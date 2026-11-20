"""Render a 3D model at the exact 2:1 isometric game camera (framework sections 1 and 20).

  blender -b -P tools/blender_render_iso.py -- <model.glb|.fbx|.obj> <out.png> [height_m] [ss] [rot_deg]

- Orthographic camera 30 degrees above the ground and 45 degrees around: ground edges come out at
  exactly 1 px down per 2 px across. The model's front (-Y) faces down-left, its +X side down-right.
- Heights are squashed by 0.8165 so 1 m of height is 16 px, like 1 m along the ground (a storey is 48 px).
- Toon shading (3 flat light bands), sun from the top-left of the screen, transparent background.
- Renders at ss x game scale; tools/pixelize.py --iso shrinks it to 1x.
- height_m: scale the model to this height in metres ("-" keeps its size). rot_deg: turn it first.
"""
import math
import sys

import bpy
from mathutils import Matrix, Vector

argv = sys.argv[sys.argv.index("--") + 1:]
src, out = argv[0], argv[1]
height_m = float(argv[2]) if len(argv) > 2 and argv[2] != "-" else None
ss = int(argv[3]) if len(argv) > 3 else 4
rot = math.radians(float(argv[4])) if len(argv) > 4 else 0.0

ELEV = math.radians(30)      # camera elevation above the ground plane -> 2:1 ground edges
AZIM = math.radians(45)
Z_SQUASH = math.cos(math.radians(45)) / math.cos(ELEV)   # 0.8165: height 16 px/m like the ground
PLANE_PX_PER_M = 16 / math.cos(math.radians(45))          # 22.63 px per metre on the camera plane

bpy.ops.wm.read_factory_settings(use_empty=True)
ext = src.lower().rsplit(".", 1)[-1]
if ext in ("glb", "gltf"):
    bpy.ops.import_scene.gltf(filepath=src)
elif ext == "fbx":
    bpy.ops.import_scene.fbx(filepath=src)
elif ext == "obj":
    bpy.ops.wm.obj_import(filepath=src)
else:
    raise SystemExit(f"unsupported model type: {ext}")
scene = bpy.context.scene
meshes = [o for o in scene.objects if o.type == "MESH"]


def toon(mat):
    """3 flat light bands (cooler shadow, mid, warmer light) times the material's own colour."""
    if not mat.use_nodes:
        return
    nt = mat.node_tree
    bsdf = next((n for n in nt.nodes if n.type == "BSDF_PRINCIPLED"), None)
    out_node = next((n for n in nt.nodes if n.type == "OUTPUT_MATERIAL"), None)
    if bsdf is None or out_node is None:
        return
    base_in, alpha_in = bsdf.inputs["Base Color"], bsdf.inputs["Alpha"]
    diffuse = nt.nodes.new("ShaderNodeBsdfDiffuse")
    to_rgb = nt.nodes.new("ShaderNodeShaderToRGB")
    bw = nt.nodes.new("ShaderNodeRGBToBW")
    ramp = nt.nodes.new("ShaderNodeValToRGB")
    ramp.color_ramp.interpolation = "CONSTANT"
    e = ramp.color_ramp.elements
    e[0].position, e[0].color = 0.0, (0.42, 0.40, 0.55, 1)
    e[1].position, e[1].color = 0.45, (0.78, 0.76, 0.80, 1)
    top = e.new(0.8)
    top.color = (1.05, 1.0, 0.92, 1)
    mix = nt.nodes.new("ShaderNodeMix")
    mix.data_type, mix.blend_type = "RGBA", "MULTIPLY"
    mix.inputs["Factor"].default_value = 1.0
    emit = nt.nodes.new("ShaderNodeEmission")
    transp = nt.nodes.new("ShaderNodeBsdfTransparent")
    mixsh = nt.nodes.new("ShaderNodeMixShader")
    L = nt.links.new
    L(diffuse.outputs["BSDF"], to_rgb.inputs["Shader"])
    L(to_rgb.outputs["Color"], bw.inputs["Color"])
    L(bw.outputs["Val"], ramp.inputs["Fac"])
    L(ramp.outputs["Color"], mix.inputs["A"])
    if base_in.is_linked:
        L(base_in.links[0].from_socket, mix.inputs["B"])
    else:
        mix.inputs["B"].default_value = base_in.default_value
    L(mix.outputs["Result"], emit.inputs["Color"])
    L(transp.outputs["BSDF"], mixsh.inputs[1])
    L(emit.outputs["Emission"], mixsh.inputs[2])
    if alpha_in.is_linked:
        L(alpha_in.links[0].from_socket, mixsh.inputs["Fac"])
    else:
        mixsh.inputs["Fac"].default_value = alpha_in.default_value
    L(mixsh.outputs["Shader"], out_node.inputs["Surface"])


for o in meshes:
    for slot in o.material_slots:
        if slot.material:
            toon(slot.material)


def world_points():
    bpy.context.view_layer.update()
    return [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]


# parent everything to a root: rotate, scale to height, squash heights, stand on the origin
root = bpy.data.objects.new("root", None)
scene.collection.objects.link(root)
for o in list(scene.objects):
    if o.parent is None and o is not root:
        o.parent = root
root.rotation_euler = (0, 0, rot)
pts = world_points()
zmin, zmax = min(p.z for p in pts), max(p.z for p in pts)
s = height_m / max(zmax - zmin, 1e-6) if height_m else 1.0
root.scale = (s, s, s * Z_SQUASH)
pts = world_points()
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
root.location -= Vector(((lo.x + hi.x) / 2, (lo.y + hi.y) / 2, lo.z))
pts = world_points()

# camera: looking from +X/-Y, so the -Y front shows down-left and the +X side down-right
cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam)
cam.rotation_euler = (math.pi / 2 - ELEV, 0, AZIM)
view_dir = cam.rotation_euler.to_matrix() @ Vector((0, 0, -1))
centre = sum(pts, Vector()) / len(pts)
cam.location = centre - view_dir * 200
bpy.context.view_layer.update()
inv = cam.matrix_world.inverted()
cp = [inv @ p for p in pts]
xmin, xmax = min(p.x for p in cp), max(p.x for p in cp)
ymin, ymax = min(p.y for p in cp), max(p.y for p in cp)
pad = 0.4
cam.location = cam.matrix_world @ Vector(((xmin + xmax) / 2, (ymin + ymax) / 2, 0))
w_m, h_m = xmax - xmin + pad, ymax - ymin + pad
cam_data.ortho_scale = max(w_m, h_m)
scene.camera = cam
scene.render.resolution_x = int(math.ceil(w_m * PLANE_PX_PER_M * ss))
scene.render.resolution_y = int(math.ceil(h_m * PLANE_PX_PER_M * ss))
scene.render.resolution_percentage = 100

# sun from the top-left of the screen (and a little from the camera side)
right = cam.rotation_euler.to_matrix() @ Vector((1, 0, 0))
light_from = (-right * 0.7 + Vector((0, 0, 1.0)) - view_dir * 0.35).normalized()
sun_data = bpy.data.lights.new("sun", "SUN")
sun_data.energy = 3.0
sun = bpy.data.objects.new("sun", sun_data)
scene.collection.objects.link(sun)
sun.rotation_euler = (-light_from).to_track_quat("-Z", "Y").to_euler()
world = bpy.data.worlds.new("w")
scene.world = world

engines = [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items]
scene.render.engine = "BLENDER_EEVEE_NEXT" if "BLENDER_EEVEE_NEXT" in engines else "BLENDER_EEVEE"
scene.render.film_transparent = True
scene.view_settings.view_transform = "Standard"
scene.render.image_settings.file_format = "PNG"
scene.render.image_settings.color_mode = "RGBA"
scene.render.filepath = out
bpy.ops.render.render(write_still=True)
fp = (hi.x - lo.x, hi.y - lo.y)
print(f"RENDERED {out} {scene.render.resolution_x}x{scene.render.resolution_y} "
      f"footprint {fp[0]:.2f} x {fp[1]:.2f} m, height {(hi.z - lo.z) / Z_SQUASH:.2f} m")
