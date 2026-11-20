"""Prepare everyday traffic vehicles from the GTAYGN UNITY project for the seaside town.

Blender 5.x:  blender -b -P tools/prepare_vehicles.py
For each source GLB: import, join all meshes, decimate to a triangle budget, rotate so the vehicle
faces -Z (Godot forward), scale to a real length, drop it onto y=0 centred on the origin, export GLB.
Originals are never modified. Writes campus_terrain/models/vehicles/<name>.glb and credits.json.
"""
import bpy
import json
import math
import os
from mathutils import Vector

SRC = r"C:\Users\khant\OneDrive\Documents\Portfolio\GTAYGN UNITY\Assets\GTAYGN\Resources\Vehicles"
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "campus_terrain", "models", "vehicles")
# name: (kind, real length m, triangle budget)
PICK = {
    "t_hilux": ("car", 5.3, 8000), "t_markii": ("car", 4.8, 8000), "t_tucson": ("car", 4.5, 8000),
    "t_hiace": ("van", 5.3, 8000), "t_crown": ("taxi", 4.7, 8000), "t_camry": ("car", 4.8, 8000),
    "t_wagonr": ("car", 3.4, 8000), "t_fit": ("car", 3.9, 8000),
    "hdPolice": ("police_bike", 2.4, 6000),
    "yz250": ("bike", 2.2, 5000), "superDuke": ("bike", 2.1, 5000), "cubC70": ("bike", 1.9, 5000), "superCub": ("bike", 1.9, 5000),
}


def clear():
    bpy.ops.wm.read_factory_settings(use_empty=True)


def prepare(name, kind, length, budget):
    clear()
    bpy.ops.import_scene.gltf(filepath=os.path.join(SRC, name + ".glb"))
    meshes = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    # Bake parent transforms into the meshes, then join into one object.
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    bpy.ops.object.join()
    obj = bpy.context.view_layer.objects.active
    for o in list(bpy.context.scene.objects):
        if o != obj:
            bpy.data.objects.remove(o, do_unlink=True)
    tris = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    if tris > budget:
        mod = obj.modifiers.new("decimate", "DECIMATE")
        mod.ratio = max(0.02, budget / tris)
        bpy.ops.object.modifier_apply(modifier=mod.name)
    # Orient: longest horizontal axis is the vehicle's length; make it run along Z.
    bb = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    size = Vector((max(v.x for v in bb) - min(v.x for v in bb), max(v.y for v in bb) - min(v.y for v in bb), max(v.z for v in bb) - min(v.z for v in bb)))
    # Blender is Z-up here (glTF importer converts); length lies along X or Y.
    if size.x > size.y:
        obj.rotation_euler[2] += math.pi / 2
        bpy.ops.object.transform_apply(rotation=True)
    bb = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    ylen = max(v.y for v in bb) - min(v.y for v in bb)
    s = length / max(ylen, 0.001)
    obj.scale = (s, s, s)
    bpy.ops.object.transform_apply(scale=True)
    bb = [obj.matrix_world @ Vector(c) for c in obj.bound_box]
    centre = Vector(((max(v.x for v in bb) + min(v.x for v in bb)) / 2, (max(v.y for v in bb) + min(v.y for v in bb)) / 2, min(v.z for v in bb)))
    obj.location -= centre
    bpy.ops.object.transform_apply(location=True)
    os.makedirs(OUT, exist_ok=True)
    out = os.path.join(OUT, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", use_selection=False, export_apply=True,
                              export_image_format="JPEG", export_jpeg_quality=80)
    final = sum(len(p.vertices) - 2 for p in obj.data.polygons)
    return {"tris_before": tris, "tris_after": final, "length_m": length, "kind": kind}


report = {}
only = [n for n in os.environ.get("ONLY", "").split(",") if n]
for name, (kind, length, budget) in PICK.items():
    if only and name not in only:
        continue
    try:
        report[name] = prepare(name, kind, length, budget)
        print("PREPARED", name, report[name])
    except Exception as exc:  # keep going; report the failure
        report[name] = {"error": str(exc)}
        print("FAILED", name, exc)
credits = json.load(open(os.path.join(SRC, "credits.json"), encoding="utf-8"))
cred_path = os.path.join(OUT, "credits.json")
out_credits = json.load(open(cred_path, encoding="utf-8")) if os.path.exists(cred_path) else {}
out_credits.update({n: {**credits[n], **report[n]} for n in report if n in credits})
json.dump(out_credits, open(cred_path, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
print("VEHICLES_DONE", len([r for r in report.values() if "error" not in r]))
