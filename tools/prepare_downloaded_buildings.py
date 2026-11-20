"""Make reduced prototype copies; preserve original downloads and review staging."""
import bpy, sys, json
from pathlib import Path
from mathutils import Vector

root = Path(sys.argv[sys.argv.index('--')+1])
stage = root/'assets3d/_incoming/downloaded_buildings_20261119'
dest = root/'campus_terrain/models/downloaded_buildings'
dest.mkdir(parents=True,exist_ok=True)
for name, filename in [('futuristic_tower','futuristic tower 3d model.glb'),('neo_utopian_city','neo utopian city 3d model.glb')]:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(Path.home()/'Downloads'/filename))
    meshes = [o for o in bpy.context.scene.objects if o.type=='MESH']
    total = sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)
    for obj in meshes:
        bpy.context.view_layer.objects.active=obj
        obj.select_set(True)
        modifier=obj.modifiers.new('PrototypeBudget','DECIMATE')
        modifier.ratio=min(1.0,28000/total)
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.select_set(False)
    bpy.context.view_layer.update()
    points=[o.matrix_world@Vector(c) for o in meshes for c in o.bound_box]
    lo=Vector([min(p[i] for p in points) for i in range(3)])
    hi=Vector([max(p[i] for p in points) for i in range(3)])
    shift=Vector(((lo.x+hi.x)/2,(lo.y+hi.y)/2,lo.z))
    for obj in meshes: obj.location-=shift
    for image in bpy.data.images:
        if image.size[0]>2048 or image.size[1]>2048:
            image.scale(2048,2048)
    bpy.ops.export_scene.gltf(filepath=str(stage/(name+'_prototype.glb')),export_format='GLB')
    import shutil
    shutil.copy2(stage/(name+'_prototype.glb'),dest/(name+'.glb'))
    report={'source':filename,'original_triangles':total,'prototype_triangles':sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes),'status':'Prototype exterior only; roof, door, emissive separation and interior still require production preparation.'}
    (stage/(name+'_preparation.json')).write_text(json.dumps(report,indent=2))
    print(report,flush=True)
