"""Inspect original building downloads and render review views in incoming staging."""
import bpy, sys, json, math
from pathlib import Path
from mathutils import Vector

out = Path(sys.argv[sys.argv.index('--') + 1])
sources = [('futuristic_tower', 'futuristic tower 3d model.glb'), ('neo_utopian_city', 'neo utopian city 3d model.glb')]
for name, filename in sources:
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=str(Path.home() / 'Downloads' / filename))
    meshes = [o for o in bpy.context.scene.objects if o.type == 'MESH']
    points = [o.matrix_world @ Vector(c) for o in meshes for c in o.bound_box]
    lo = Vector([min(p[i] for p in points) for i in range(3)])
    hi = Vector([max(p[i] for p in points) for i in range(3)])
    info = {'source': filename, 'bounds': list(hi-lo), 'objects': [o.name for o in meshes], 'triangles': sum(sum(len(p.vertices)-2 for p in o.data.polygons) for o in meshes)}
    (out / (name+'_review.json')).write_text(json.dumps(info, indent=2))
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.samples = 8
    scene.render.resolution_x = scene.render.resolution_y = 640
    scene.render.resolution_percentage = 100
    scene.world = bpy.data.worlds.new('ReviewWorld')
    scene.world.use_nodes = True
    scene.world.node_tree.nodes['Background'].inputs[0].default_value = (0.65,0.72,0.8,1)
    scene.world.node_tree.nodes['Background'].inputs[1].default_value = 0.8
    light_data = bpy.data.lights.new('Key','SUN')
    light_data.energy = 2
    light = bpy.data.objects.new('Key',light_data)
    scene.collection.objects.link(light)
    light.rotation_euler = (0.4,-0.5,-0.4)
    cam_data = bpy.data.cameras.new('ReviewCamera')
    cam_data.type = 'ORTHO'
    cam_data.ortho_scale = max(hi-lo)*1.65
    cam = bpy.data.objects.new('ReviewCamera',cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    centre = (hi+lo)/2
    cam.location = centre + Vector((1,-1,0.8))*max(hi-lo)*2
    cam.rotation_euler = (centre-cam.location).to_track_quat('-Z','Y').to_euler()
    scene.render.filepath = str(out / (name+'_review.png'))
    bpy.ops.render.render(write_still=True)
    print(name,info)
