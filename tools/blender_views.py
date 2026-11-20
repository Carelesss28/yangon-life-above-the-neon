"""Diagnostic: render a model from 5 sides (south, north, west, east, top) to check its orientation.

  blender -b -P tools/blender_views.py -- <model> <out_prefix>
"""
import math
import sys

import bpy
from mathutils import Vector

argv = sys.argv[sys.argv.index("--") + 1:]
src, prefix = argv[0], argv[1]
bpy.ops.wm.read_factory_settings(use_empty=True)
if src.lower().endswith((".glb", ".gltf")):
    bpy.ops.import_scene.gltf(filepath=src)
else:
    bpy.ops.import_scene.fbx(filepath=src)
meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
bpy.context.view_layer.update()
pts = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
lo = Vector((min(p.x for p in pts), min(p.y for p in pts), min(p.z for p in pts)))
hi = Vector((max(p.x for p in pts), max(p.y for p in pts), max(p.z for p in pts)))
c = (lo + hi) / 2
size = max(hi - lo) * 1.2
print(f"BOUNDS x {lo.x:.2f}..{hi.x:.2f}  y {lo.y:.2f}..{hi.y:.2f}  z {lo.z:.2f}..{hi.z:.2f}")

scene = bpy.context.scene
cam_data = bpy.data.cameras.new("cam")
cam_data.type = "ORTHO"
cam_data.ortho_scale = size
cam = bpy.data.objects.new("cam", cam_data)
scene.collection.objects.link(cam)
scene.camera = cam
world = bpy.data.worlds.new("w")
world.use_nodes = True
world.node_tree.nodes["Background"].inputs[1].default_value = 2.5
scene.world = world
scene.render.film_transparent = True
scene.render.resolution_x = scene.render.resolution_y = 400
scene.view_settings.view_transform = "Standard"
d = size * 3
views = {
    "south": (Vector((0, -d, 0)), (math.pi / 2, 0, 0)),
    "north": (Vector((0, d, 0)), (math.pi / 2, 0, math.pi)),
    "west": (Vector((-d, 0, 0)), (math.pi / 2, 0, -math.pi / 2)),
    "east": (Vector((d, 0, 0)), (math.pi / 2, 0, math.pi / 2)),
    "top": (Vector((0, 0, d)), (0, 0, 0)),
}
for name, (off, rot) in views.items():
    cam.location = c + off
    cam.rotation_euler = rot
    scene.render.filepath = f"{prefix}_{name}.png"
    bpy.ops.render.render(write_still=True)
print("VIEWS DONE")
