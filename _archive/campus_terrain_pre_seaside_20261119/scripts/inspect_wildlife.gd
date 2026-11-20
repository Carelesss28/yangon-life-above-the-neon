extends SceneTree
func _initialize():
 for kind in ["cat","bird","duck"]:
  var root=load("res://models/wildlife/%s.glb"%kind).instantiate()
  print(kind," root=",root.name," scale=",root.scale," pos=",root.position)
  root.print_tree_pretty()
  for mesh in root.find_children("*","MeshInstance3D",true,false):
   print(mesh.name," scale=",mesh.scale," meshbounds=",mesh.mesh.get_aabb()," mat=",mesh.get_active_material(0).albedo_color)
  root.free()
 quit()
