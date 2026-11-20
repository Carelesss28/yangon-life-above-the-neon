extends Control
## Corner minimap drawn from the town plan (no second 3D render): sea, beach, land and hills, roads,
## canals, building footprints, parks, campus, skytrain stations, quest markers and the player arrow.
## Click it to open the whole-town map; click again (or M / Tab / Esc / WASD) to return.
const Layout=preload("res://scripts/terrain_layout.gd")
const Roads=preload("res://scripts/road_layout.gd")
const SCALE=3.0          # metres per texture pixel
const VIEW_METRES=300.0  # width of the area shown around the player
var world
var map_texture: ImageTexture
var tex_size: Vector2

func _ready() -> void:
	custom_minimum_size=Vector2(230,230)
	size=Vector2(230,230)
	mouse_filter=Control.MOUSE_FILTER_STOP
	tooltip_text="Click: whole-town map"
	_build_texture()

func _build_texture() -> void:
	var w=int(Layout.WORLD.size.x/SCALE)
	var h=int(Layout.WORLD.size.y/SCALE)
	var img=Image.create(w,h,false,Image.FORMAT_RGBA8)
	for py in range(h):
		for px in range(w):
			var x=px*SCALE
			var z=py*SCALE
			var c: Color
			var s=Layout.shore(x)
			if z<s-1.5:
				c=Color("2f8fb8") if Layout.harbour_weight(x)<0.5 else Color("2a7fa6")
			elif z<s+0.5:
				c=Color("e6d3a0")
			else:
				var hgt=Layout.natural_height_at(x,z)
				c=Color("8cc46a").lerp(Color("4f7f45"),clampf((hgt-6.0)/30.0,0,1))
				if Layout.wet(x,z): c=Color("3a9cc8")
			img.set_pixel(px,py,c)
	# Promenade strip.
	for px in range(w):
		var x=px*SCALE
		for z in range(int(Layout.shore(x)),227,int(SCALE)):
			_dot(img,Vector2(x,z),Color("efe2c4"),1)
	for entry in world.parks:
		_rect(img,entry.rect,Color("6fbf5a"))
	_rect(img,Layout.CAMPUS,Color(0.62,0.52,0.82,0.55),true)
	for route in Layout.WATER_ROUTES:
		for i in range(route.points.size()-1):
			_line(img,Vector2(route.points[i].x,route.points[i].z),Vector2(route.points[i+1].x,route.points[i+1].z),Color("3aa4d8"),2)
	for edge in Roads.EDGES:
		var a: Vector3=Roads.NODES[edge[0]]
		var b: Vector3=Roads.NODES[edge[1]]
		_line(img,Vector2(a.x,a.z),Vector2(b.x,b.z),Color("5a5f6a"),maxi(1,int(Roads.width(edge)/SCALE/2)))
	for entry in world.building_plots:
		var r: Rect2=entry.plot
		var shop=entry.label=="SHOPHOUSE ROW"
		_rect(img,r.grow(-1.0 if shop else -3.0),Color("f2b8a8") if shop else Color("e8e4dc"))
	map_texture=ImageTexture.create_from_image(img)
	tex_size=Vector2(w,h)

func _to_px(p: Vector2) -> Vector2:
	return p/SCALE

func _dot(img: Image,p: Vector2,c: Color,r: int) -> void:
	var q=_to_px(p)
	for dx in range(-r+1,r):
		for dy in range(-r+1,r):
			var x=int(q.x)+dx
			var y=int(q.y)+dy
			if x>=0 and y>=0 and x<img.get_width() and y<img.get_height(): img.set_pixel(x,y,c)

func _line(img: Image,a: Vector2,b: Vector2,c: Color,thick: int) -> void:
	var steps=int(a.distance_to(b)/SCALE)+1
	for i in range(steps+1):
		_dot(img,a.lerp(b,float(i)/steps),c,thick)

func _rect(img: Image,r: Rect2,c: Color,blend=false) -> void:
	var a=_to_px(r.position)
	var b=_to_px(r.end)
	for x in range(int(a.x),int(b.x)):
		for y in range(int(a.y),int(b.y)):
			if x<0 or y<0 or x>=img.get_width() or y>=img.get_height(): continue
			img.set_pixel(x,y,img.get_pixel(x,y).lerp(c,c.a) if blend else c)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		if world.camera.masterplan: world.close_maps()
		else: world.toggle_masterplan()
		accept_event()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	if world==null or world.player==null: return
	var box=Rect2(Vector2.ZERO,size)
	draw_rect(box.grow(3),Color(0.06,0.05,0.12,0.92))
	var p=Vector2(world.player.global_position.x,world.player.global_position.z)
	var src_size=Vector2(VIEW_METRES,VIEW_METRES)/SCALE
	var src_pos=_to_px(p)-src_size/2
	draw_texture_rect_region(map_texture,box,Rect2(src_pos,src_size))
	var k=size.x/VIEW_METRES
	var to_screen=func(q: Vector2) -> Vector2: return size/2+(q-p)*k
	# Skytrain stations.
	if world.skytrain:
		for station in world.skytrain.stations:
			var s: Vector2=to_screen.call(Vector2(station.ground.x,station.ground.z))
			if box.has_point(s): draw_rect(Rect2(s-Vector2(3,3),Vector2(6,6)),Color("2fe6e0"))
	# People with a quest marker.
	if world.npcs:
		for npc in world.npcs.npcs:
			if not npc.node.visible: continue
			var m: String=world.npcs._quest_marker(npc)
			if m=="": continue
			var s: Vector2=to_screen.call(Vector2(npc.node.position.x,npc.node.position.z))
			if box.has_point(s): draw_circle(s,4.0,Color("ffcf3a"))
	# Player arrow, pointing where the student faces.
	var yaw=0.0
	if world.player.visual: yaw=world.player.visual.global_rotation.y
	var fwd=Vector2(-sin(yaw),-cos(yaw))
	var side=Vector2(-fwd.y,fwd.x)
	var c=size/2
	draw_colored_polygon(PackedVector2Array([c+fwd*9,c-fwd*5+side*6,c-fwd*2,c-fwd*5-side*6]),Color("ff3d9a"))
	draw_rect(box,Color("b07dff"),false,2.0)
	draw_string(ThemeDB.fallback_font,Vector2(8,size.y-8),"N ↑   click: town map",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("f2e8ff"))
