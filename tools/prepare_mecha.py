"""Prepare the user's four Tripo mecha downloads for the YUST mecha hangar.

blender -b -P tools/prepare_mecha.py
Imports each model (GLB or FBX), joins meshes, decimates to a triangle budget, scales to a standing
height of 10 m, puts the feet on z=0 centred on the origin, exports GLB to campus_terrain/models/mecha/
and renders a front / side review image. Originals in Downloads are never modified.
"""
import bpy
import math
import os
from mathutils import Vector

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DL = r"C:\Users\khant\Downloads"
SCR = os.environ.get("MECHA_IN", "")
OUT = os.path.join(ROOT, "campus_terrain", "models", "mecha")
REVIEW = os.path.join(ROOT, "assets3d", "_incoming", "mecha_20261120")
SOURCES = [
    ("mecha_1", os.path.join(DL, "tripo_convert_585a9362-8037-41bf-be41-a31c28a8dd8c.glb")),
    ("mecha_2", os.path.join(DL, "tripo_convert_2d900645-efc3-45f2-a908-c8cd467da88f.glb")),
    ("mecha_3", os.path.join(SCR, "a", "tripo_convert_8ef594e2-a21f-4773-b2c2-f8f64f3d03e0.fbx")),
    ("mecha_4", os.path.join(SCR, "b", "tripo_convert_1d3409cb-7c5c-497f-a3f9-2554a64391a9.fbx")),
]
HEIGHT = 10.0
BUDGET = 30000
# Reused for characters: PREP_JSON='{"height":1.7,"budget":20000,"out":"...","review":"...","sources":[[name,path],...]}'
import json as _json
if os.environ.get("PREP_JSON"):
    _cfg = _json.loads(os.environ["PREP_JSON"])
    HEIGHT = float(_cfg.get("height", HEIGHT))
    BUDGET = int(_cfg.get("budget", BUDGET))
    OUT = _cfg.get("out", OUT)
    REVIEW = _cfg.get("review", REVIEW)
    SOURCES = [tuple(x) for x in _cfg["sources"]]


def prepare(name, path):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    if path.lower().endswith(".fbx"):
        bpy.ops.import_scene.fbx(filepath=path)
    else:
        bpy.ops.import_scene.gltf(filepath=path)
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    for o in list(bpy.context.scene.objects):
        if o != obj:
            bpy.data.objects.remove(o, do_unlink=True)
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    if tris > BUDGET:
        mod = obj.modifiers.new("decimate", "DECIMATE")
        mod.ratio = max(0.01, BUDGET / tris)
        bpy.ops.object.modifier_apply(modifier=mod.name)
    bb = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    height = max(v.z for v in bb) - min(v.z for v in bb)
    s = HEIGHT / max(height, 0.001)
    obj.scale = (s, s, s)
    bpy.ops.object.transform_apply(scale=True)
    bb = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    centre = Vector(((max(v.x for v in bb) + min(v.x for v in bb)) / 2, (max(v.y for v in bb) + min(v.y for v in bb)) / 2, min(v.z for v in bb)))
    obj.location -= centre
    bpy.ops.object.transform_apply(location=True)
    os.makedirs(OUT, exist_ok=True)
    bpy.ops.export_scene.gltf(filepath=os.path.join(OUT, name + ".glb"), export_format="GLB", export_image_format="JPEG", export_jpeg_quality=85)
    bb = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    dims = (max(v.x for v in bb) - min(v.x for v in bb), max(v.y for v in bb) - min(v.y for v in bb), max(v.z for v in bb) - min(v.z for v in bb))
    # Review renders from -Y (Blender front) and +X (side).
    os.makedirs(REVIEW, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE" if "BLENDER_EEVEE" in [e.identifier for e in bpy.types.RenderSettings.bl_rna.properties["engine"].enum_items] else "BLENDER_WORKBENCH"
    scene.render.resolution_x = 480
    scene.render.resolution_y = 480
    world = bpy.data.worlds.new("w")
    world.color = (0.8, 0.82, 0.85)
    scene.world = world
    light = bpy.data.objects.new("sun", bpy.data.lights.new("sun", "SUN"))
    light.rotation_euler = (math.radians(50), 0, math.radians(30))
    scene.collection.objects.link(light)
    cam = bpy.data.objects.new("cam", bpy.data.cameras.new("cam"))
    cam.data.type = "ORTHO"
    cam.data.ortho_scale = HEIGHT * 1.3
    scene.collection.objects.link(cam)
    scene.camera = cam
    for view, loc, rot in [("front", (0, -30, HEIGHT / 2), (math.radians(90), 0, 0)), ("side", (30, 0, HEIGHT / 2), (math.radians(90), 0, math.radians(90)))]:
        cam.location = loc
        cam.rotation_euler = rot
        scene.render.filepath = os.path.join(REVIEW, "%s_%s.png" % (name, view))
        bpy.ops.render.render(write_still=True)
    return tris, sum(len(p.vertices) - 2 for p in obj.data.polygons), dims


for name, path in SOURCES:
    try:
        before, after, dims = prepare(name, path)
        print("PREPARED", name, before, "->", after, "tris, size %.1f x %.1f x %.1f m" % dims)
    except Exception as exc:
        print("FAILED", name, exc)
print("MECHA_DONE")
