"""Auto-rig a prepared T-pose character (no skeleton) for the game.

blender -b -P tools/rig_character.py -- <in.glb> <out.glb>
Builds a humanoid armature fitted to the mesh proportions (feet on z=0, facing -Y), binds every vertex
to its nearest bones with smooth falloff, lowers the arms from T-pose to a relaxed A-pose and makes
that the rest pose, then exports a skinned GLB. Godot animates the bones procedurally.
"""
import bpy
import math
import sys
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, DST = argv[0], argv[1]
RELAXED = len(argv) > 2 and argv[2] == "relaxed"   # arms already hang down (no T-pose)

bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=SRC)
mesh = [o for o in bpy.context.scene.objects if o.type == "MESH"][0]
bpy.context.view_layer.objects.active = mesh
mesh.select_set(True)
bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
verts = [mesh.matrix_world @ v.co for v in mesh.data.vertices]
H = max(v.z for v in verts)

# Measure the arm span at shoulder height to place elbows and wrists.
band = [v for v in verts if 0.74 * H < v.z < 0.86 * H]
reach = max(abs(v.x) for v in band)
sh_z = 0.815 * H
J = {
    "hips": Vector((0, 0, 0.53 * H)), "spine": Vector((0, 0, 0.64 * H)), "chest": Vector((0, 0, 0.75 * H)),
    "neck": Vector((0, 0, 0.84 * H)), "head": Vector((0, 0, 0.90 * H)), "top": Vector((0, 0, 1.0 * H)),
}
for s, n in [(1, "L"), (-1, "R")]:
    J["shoulder." + n] = Vector((s * 0.10 * H, 0, sh_z))
    if RELAXED:
        J["elbow." + n] = Vector((s * 0.125 * H, 0, 0.64 * H))
        J["wrist." + n] = Vector((s * 0.14 * H, -0.01 * H, 0.48 * H))
        J["hand." + n] = Vector((s * 0.145 * H, -0.01 * H, 0.42 * H))
    else:
        J["elbow." + n] = Vector((s * (0.10 * H + (reach - 0.10 * H) * 0.42), 0, sh_z))
        J["wrist." + n] = Vector((s * (0.10 * H + (reach - 0.10 * H) * 0.80), 0, sh_z))
        J["hand." + n] = Vector((s * reach, 0, sh_z))
    J["hip." + n] = Vector((s * 0.06 * H, 0, 0.50 * H))
    J["knee." + n] = Vector((s * 0.06 * H, -0.01 * H, 0.27 * H))
    J["ankle." + n] = Vector((s * 0.06 * H, 0, 0.05 * H))
    J["toe." + n] = Vector((s * 0.06 * H, -0.09 * H, 0.01 * H))
BONES = [  # name, head joint, tail joint, parent
    ("hips", "hips", "spine", None), ("spine", "spine", "chest", "hips"), ("chest", "chest", "neck", "spine"),
    ("neck", "neck", "head", "chest"), ("head", "head", "top", "neck"),
]
for n in ["L", "R"]:
    BONES += [
        ("upper_arm." + n, "shoulder." + n, "elbow." + n, "chest"), ("forearm." + n, "elbow." + n, "wrist." + n, "upper_arm." + n),
        ("hand." + n, "wrist." + n, "hand." + n, "forearm." + n),
        ("thigh." + n, "hip." + n, "knee." + n, "hips"), ("shin." + n, "knee." + n, "ankle." + n, "thigh." + n),
        ("foot." + n, "ankle." + n, "toe." + n, "shin." + n),
    ]

arm_data = bpy.data.armatures.new("Rig")
rig = bpy.data.objects.new("Rig", arm_data)
bpy.context.scene.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="EDIT")
for name, a, b, parent in BONES:
    eb = arm_data.edit_bones.new(name)
    eb.head = J[a]
    eb.tail = J[b]
    if parent:
        eb.parent = arm_data.edit_bones[parent]
        eb.use_connect = False
bpy.ops.object.mode_set(mode="OBJECT")

# Weights: nearest bone segments with smooth falloff (robust on non-manifold generated meshes).
segs = [(name, J[a], J[b]) for name, a, b, _ in BONES]
groups = {name: mesh.vertex_groups.new(name=name) for name, _, _, _ in BONES}


def seg_dist(p, a, b):
    ab = b - a
    t = max(0.0, min(1.0, (p - a).dot(ab) / max(ab.length_squared, 1e-9)))
    return (p - (a + ab * t)).length


for i, p in enumerate(verts):
    ds = sorted(((seg_dist(p, a, b), n) for n, a, b in segs))
    # Arms only take arm vertices that are clearly out to the side; legs only below the hips.
    best = []
    for d, n in ds:
        if (n.startswith("upper_arm") or n.startswith("forearm") or n.startswith("hand")) and abs(p.x) < (0.095 if RELAXED else 0.11) * H:
            continue
        if (n.startswith("thigh") or n.startswith("shin") or n.startswith("foot")) and p.z > 0.55 * H:
            continue
        best.append((d, n))
        if len(best) == 2:
            break
    if not best:
        best = [ds[0]]
    w = [1.0 / max(d, 0.002) ** 4 for d, _ in best]
    tot = sum(w)
    for (d, n), wi in zip(best, w):
        groups[n].add([i], wi / tot, "REPLACE")

mod = mesh.modifiers.new("Armature", "ARMATURE")
mod.object = rig
mesh.parent = rig

# Relaxed A-pose: arms down about 62 degrees, slightly forward; make it the rest pose.
bpy.context.view_layer.objects.active = rig
if RELAXED:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.export_scene.gltf(filepath=DST, export_format="GLB", export_skins=True, export_image_format="JPEG", export_jpeg_quality=85)
    print("RIGGED", DST, "relaxed, height %.2f" % H)
    raise SystemExit
bpy.ops.object.mode_set(mode="POSE")
for n, s in [("L", -1), ("R", 1)]:
    pb = rig.pose.bones["upper_arm." + n]
    pb.rotation_mode = "XYZ"
    # Rotate around the world forward axis (Y) in the bone's frame.
    world_axis = Vector((0, 1, 0))
    local_axis = (pb.bone.matrix_local.to_3x3().inverted() @ world_axis).normalized()
    pb.rotation_mode = "AXIS_ANGLE"
    pb.rotation_axis_angle = (math.radians(62) * s, local_axis.x, local_axis.y, local_axis.z)
    bpy.context.view_layer.update()
    # The hand must end up below the shoulder; if this side went up, rotate the other way.
    if (rig.matrix_world @ pb.tail).z > (rig.matrix_world @ pb.head).z:
        pb.rotation_axis_angle = (-math.radians(62) * s, local_axis.x, local_axis.y, local_axis.z)
        bpy.context.view_layer.update()
    print("ARM", n, "hand z %.2f shoulder z %.2f" % ((rig.matrix_world @ pb.tail).z, (rig.matrix_world @ pb.head).z))
bpy.ops.object.mode_set(mode="OBJECT")
bpy.context.view_layer.objects.active = mesh
bpy.ops.object.modifier_apply(modifier="Armature")
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode="POSE")
bpy.ops.pose.armature_apply(selected=False)
bpy.ops.object.mode_set(mode="OBJECT")
mod = mesh.modifiers.new("Armature", "ARMATURE")
mod.object = rig

bpy.ops.object.select_all(action="SELECT")
bpy.ops.export_scene.gltf(filepath=DST, export_format="GLB", export_skins=True, export_image_format="JPEG", export_jpeg_quality=85)
print("RIGGED", DST, "height %.2f reach %.2f" % (H, reach))
