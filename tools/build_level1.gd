extends SceneTree
# Genera res://scenes/levels/Level1.tscn y su TileSet a partir del diseño de abajo.
#
# Uso (desde la carpeta del proyecto):
#   godot --headless --path . --script res://tools/build_level1.gd
#
# Después de generarlo, el nivel se puede seguir editando a mano en el editor
# de Godot (pintar tiles en el nodo Ground, mover trampas, letreros, etc.).
# OJO: volver a correr este script sobrescribe esos cambios.

const T := 32
const W := 150
const H := 20

const TILE_GRASS := Vector2i(0, 0)
const TILE_DIRT := Vector2i(1, 0)
const TILE_PLANK := Vector2i(2, 0)
const TILE_DIRT_DARK := Vector2i(3, 0)

const OUT_SCENE := "res://scenes/levels/Level1.tscn"
const OUT_TILESET := "res://assets/tilesets/level1_tileset.tres"

var solid := {}
var planks: Array[Vector2i] = []
var level: Node2D

func _initialize() -> void:
	_design()
	var tileset := _build_tileset()
	level = Node2D.new()
	level.name = "Level1"
	level.set_script(load("res://scripts/Level1.gd"))
	level.character1_scene = load("res://scenes/entities/Character1.tscn")
	level.secret_scene = load("res://scenes/entities/CharacterSecret.tscn")
	level.ghost_scene = load("res://scenes/entities/GhostEnemy.tscn")
	level.level_size = Vector2i(W * T, H * T)

	_build_background()
	_build_far_side()
	_build_decor()
	_build_ground(tileset)
	_build_hidden_cave(tileset)
	_build_entities()
	_build_enemies()
	_build_triggers()

	var hud: Node = load("res://scenes/ui/HUD.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	_add(level, hud)

	var packed := PackedScene.new()
	var err := packed.pack(level)
	if err == OK:
		err = ResourceSaver.save(packed, OUT_SCENE)
	print("Level1 generado: ", error_string(err))
	level.free()
	quit()

# --------------------------------------------------------------------------
# Diseño del nivel (coordenadas en tiles; la fila 17 es el suelo base)
# --------------------------------------------------------------------------
func _design() -> void:
	_fill(0, 1, 0, 19)                     # pared izquierda
	# A — inicio: aprender a moverse y saltar
	_fill(2, 19, 17, 19)
	_fill(14, 15, 16, 16)
	# hueco pequeño 20-22
	# B — aprender el paraguas
	_fill(23, 31, 17, 19)
	_fill(28, 31, 15, 16)
	# abismo ancho 32-40 (requiere planear)
	# C — primera trampa
	_fill(41, 49, 17, 19)
	_plank(44, 48, 14)
	# D — exploración vertical sobre pinchos
	_fill(50, 58, 17, 19)
	_plank(50, 52, 14)
	_plank(54, 56, 11)
	_plank(56, 58, 14)   # caminando por aquí se entra "por accidente" a la cueva
	# Colina alta con cueva secreta (zona de alto riesgo)
	_fill(59, 80, 8, 19)
	_carve(59, 64, 12, 16)
	# abismo 81-88 con un tablón a medio camino
	_plank(84, 85, 9)
	# F — llanura con trampa
	_fill(89, 104, 10, 19)
	_plank(93, 97, 7)
	_fill(101, 104, 8, 9)
	# G — zona elevada: aquí se descubre que el puente desapareció
	_fill(105, 118, 6, 19)
	# precipicio 119-134 (el puente ya no está)
	# Colina de la carpintera
	_fill(135, 147, 7, 19)
	_fill(148, 149, 0, 19)

func _fill(x0: int, x1: int, y0: int, y1: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			solid[Vector2i(x, y)] = true

func _carve(x0: int, x1: int, y0: int, y1: int) -> void:
	for y in range(y0, y1 + 1):
		for x in range(x0, x1 + 1):
			solid.erase(Vector2i(x, y))

func _plank(x0: int, x1: int, y: int) -> void:
	for x in range(x0, x1 + 1):
		planks.append(Vector2i(x, y))

func _tile_pos(tx: float, ty: float) -> Vector2:
	return Vector2(tx * T, ty * T)

# --------------------------------------------------------------------------
func _build_tileset() -> TileSet:
	var ts := TileSet.new()
	ts.tile_size = Vector2i(T, T)
	ts.add_physics_layer()
	var src := TileSetAtlasSource.new()
	src.texture = load("res://assets/sprites/tiles/level1_tiles.png")
	src.texture_region_size = Vector2i(T, T)
	ts.add_source(src, 0)
	var h := T / 2.0
	var full := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, h), Vector2(-h, h)])
	# el tablón solo tiene colisión en su parte de arriba
	var thin := PackedVector2Array([Vector2(-h, -h), Vector2(h, -h), Vector2(h, -h * 0.4), Vector2(-h, -h * 0.4)])
	for coords in [TILE_GRASS, TILE_DIRT, TILE_PLANK, TILE_DIRT_DARK]:
		src.create_tile(coords)
		var td := src.get_tile_data(coords, 0)
		td.add_collision_polygon(0)
		if coords == TILE_PLANK:
			td.set_collision_polygon_points(0, 0, thin)
			td.set_collision_polygon_one_way(0, 0, true)
		else:
			td.set_collision_polygon_points(0, 0, full)
	DirAccess.make_dir_recursive_absolute(OUT_TILESET.get_base_dir())
	ResourceSaver.save(ts, OUT_TILESET)
	return load(OUT_TILESET)

func _ground_tile(cell: Vector2i) -> Vector2i:
	if not solid.has(cell + Vector2i.UP):
		return TILE_GRASS
	# más adentro de la tierra se ve más oscuro
	if solid.has(cell + Vector2i(0, -3)) and solid.has(cell + Vector2i(-1, 0)) and solid.has(cell + Vector2i(1, 0)):
		return TILE_DIRT_DARK
	return TILE_DIRT

func _build_ground(tileset: TileSet) -> void:
	var layer := TileMapLayer.new()
	layer.name = "Ground"
	layer.tile_set = tileset
	for cell in solid:
		layer.set_cell(cell, 0, _ground_tile(cell))
	for cell in planks:
		layer.set_cell(cell, 0, TILE_PLANK)
	_add(level, layer)

func _build_hidden_cave(tileset: TileSet) -> void:
	# Capa que tapa la cueva; se vuelve transparente cuando el jugador entra
	var cover := TileMapLayer.new()
	cover.name = "HiddenCover"
	cover.tile_set = tileset
	cover.collision_enabled = false
	cover.z_index = 5
	# Se calcula qué tile habría ahí si la colina estuviera completa, para que
	# la tapa sea idéntica al resto de la colina
	var cave: Array[Vector2i] = []
	for y in range(12, 17):
		for x in range(59, 65):
			cave.append(Vector2i(x, y))
	for c in cave:
		solid[c] = true
	for c in cave:
		cover.set_cell(c, 0, _ground_tile(c))
	for c in cave:
		solid.erase(c)
	_add(level, cover)

	var zone := _area("HiddenZone", Rect2(_tile_pos(59, 12), Vector2(6 * T, 6 * T)))
	_connect(zone, "body_entered", "_on_hidden_zone_body_entered")
	_connect(zone, "body_exited", "_on_hidden_zone_body_exited")

	var col: Node2D = load("res://scenes/entities/Collectible.tscn").instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
	col.name = "Collectible"
	col.collectible_id = "collectible1"
	col.position = _tile_pos(63.5, 16.4)
	_add(level, col)

# --------------------------------------------------------------------------
func _build_background() -> void:
	var sky_layer := CanvasLayer.new()
	sky_layer.name = "Sky"
	sky_layer.layer = -10
	_add(level, sky_layer)
	var sky := TextureRect.new()
	sky.name = "SkyTexture"
	sky.texture = load("res://assets/sprites/backgrounds/sky.png")
	_add(sky_layer, sky)

	var layers := [
		["Clouds", "clouds.png", 0.05, 6.0],
		["HillsFar", "hills_far.png", 0.2, 0.0],
		["HillsNear", "hills_near.png", 0.45, 0.0],
	]
	for l in layers:
		var p := Parallax2D.new()
		p.name = l[0]
		p.scroll_scale = Vector2(l[2], 0.0)
		p.repeat_size = Vector2(640, 0)
		p.repeat_times = 3
		p.autoscroll = Vector2(l[3], 0)
		p.z_index = -9
		_add(level, p)
		var s := Sprite2D.new()
		s.name = "Sprite2D"
		s.texture = load("res://assets/sprites/backgrounds/" + l[1])
		s.centered = false
		_add(p, s)

func _sprite(parent: Node, n: String, tex: String, pos: Vector2, flip := false) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = n
	s.texture = load("res://assets/sprites/props/" + tex)
	s.centered = false
	s.position = pos
	s.flip_h = flip
	_add(parent, s)
	return s

func _build_decor() -> void:
	var decor := Node2D.new()
	decor.name = "Decor"
	decor.z_index = -1
	_add(level, decor)
	# (x en tiles, fila del suelo, sprite)
	var items := [
		[3, 17, "fence.png"], [4, 17, "fence.png"], [8, 17, "tree.png"], [17, 17, "bush.png"],
		[24, 17, "bush.png"], [42, 17, "tree.png"], [47.5, 17, "bush.png"],
		[66, 8, "tree.png"], [71, 8, "fence.png"], [72, 8, "fence.png"], [77, 8, "bush.png"],
		[90, 10, "bush.png"], [99, 10, "tree.png"], [106, 6, "bush.png"],
		[110, 6, "fence.png"], [111, 6, "fence.png"], [112, 6, "fence.png"],
		[144, 7, "tree.png"], [137, 7, "bush.png"],
	]
	var i := 0
	for it in items:
		var tex: Texture2D = load("res://assets/sprites/props/" + it[2])
		_sprite(decor, "Decor%d" % i, it[2], _tile_pos(it[0], it[1]) - Vector2(0, tex.get_height()))
		i += 1

func _build_far_side() -> void:
	var far := Node2D.new()
	far.name = "CarpenterHill"
	_add(level, far)
	_sprite(far, "House", "house.png", Vector2(139 * T, 7 * T - 3 * T))
	# Postes del puente: la cuerda rota cuelga hacia el precipicio
	_sprite(far, "BridgePostLeft", "bridge_post.png", Vector2(119 * T - T / 2, 6 * T - 1.5 * T))
	_sprite(far, "BridgePostRight", "bridge_post.png", Vector2(135 * T - 0.375 * T, 7 * T - 1.5 * T), true)

# --------------------------------------------------------------------------
func _build_entities() -> void:
	var start := Marker2D.new()
	start.name = "PlayerStart"
	start.position = _tile_pos(4, 17)
	_add(level, start)

	var signs := [
		[6, 17, "← → / A D : moverse"],
		[12, 17, "ESPACIO : saltar"],
		[25, 17, "Mantén ESPACIO en el aire\npara abrir el paraguas"],
		[42.5, 17, "¡Cuidado con las trampas!"],
	]
	var sign_scene: PackedScene = load("res://scenes/entities/SignPost.tscn")
	var signs_node := _group("Signs")
	for i in signs.size():
		var s: Node2D = sign_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		s.name = "Sign%d" % (i + 1)
		s.text = signs[i][2]
		s.position = _tile_pos(signs[i][0], signs[i][1])
		_add(signs_node, s)

	var cp_scene: PackedScene = load("res://scenes/entities/Checkpoint.tscn")
	var cps := _group("Checkpoints")
	var cp_pos := [[41.5, 17], [61.5, 8], [107.5, 6]]
	for i in cp_pos.size():
		var cp: Node2D = cp_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		cp.name = "Checkpoint%d" % (i + 1)
		cp.position = _tile_pos(cp_pos[i][0], cp_pos[i][1])
		_add(cps, cp)

	var spike_scene: PackedScene = load("res://scenes/entities/Spikes.tscn")
	var hazards := _group("Hazards")
	var spike_cells := []
	for x in range(45, 48):
		spike_cells.append(Vector2i(x, 16))
	for x in range(52, 59):
		spike_cells.append(Vector2i(x, 16))
	for x in range(94, 97):
		spike_cells.append(Vector2i(x, 9))
	for c in spike_cells:
		var sp: Node2D = spike_scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		sp.name = "Spikes_%d_%d" % [c.x, c.y]
		sp.position = _tile_pos(c.x, c.y)
		_add(hazards, sp)

	var ghosts := _group("GhostSpawns")
	var ghost_pos := [[72, 4], [96, 5]]
	for i in ghost_pos.size():
		var m := Marker2D.new()
		m.name = "GhostSpawn%d" % (i + 1)
		m.position = _tile_pos(ghost_pos[i][0], ghost_pos[i][1])
		_add(ghosts, m)

func _build_enemies() -> void:
	# (escena, x en tiles, y en tiles, propiedades)
	# Babosas y plantas se paran sobre la fila indicada; los saltarines
	# esperan escondidos debajo del hueco (fuera de la cámara).
	var enemies := [
		["SlimeEnemy", 9, 17, {"start_direction": 1}],
		["JumperEnemy", 21.5, 21.25, {"start_delay": 0.8}],
		["CrowEnemy", 36, 14.4, {"flight_range": 110.0}],
		["SlimeEnemy", 70, 8, {"start_direction": -1}],
		["PlantEnemy", 78.5, 8, {}],
		["JumperEnemy", 87, 21.25, {"jump_speed": 1020.0, "start_delay": 1.4}],
		["CrowEnemy", 99, 7.2, {"flight_range": 90.0, "start_direction": 1}],
		["PlantEnemy", 102.5, 8, {}],
	]
	var group := _group("Enemies")
	var counts := {}
	for e in enemies:
		var scene: PackedScene = load("res://scenes/entities/%s.tscn" % e[0])
		var node: Node2D = scene.instantiate(PackedScene.GEN_EDIT_STATE_INSTANCE)
		counts[e[0]] = counts.get(e[0], 0) + 1
		node.name = "%s%d" % [e[0], counts[e[0]]]
		node.position = _tile_pos(e[1], e[2])
		for prop in e[3]:
			node.set(prop, e[3][prop])
		_add(group, node)

func _build_triggers() -> void:
	var trigger := _area("BridgeTrigger", Rect2(_tile_pos(115, 2), Vector2(3 * T, 4 * T)))
	_connect(trigger, "body_entered", "_on_bridge_trigger_body_entered")

# --------------------------------------------------------------------------
func _group(n: String) -> Node2D:
	var g := Node2D.new()
	g.name = n
	_add(level, g)
	return g

func _area(n: String, rect: Rect2) -> Area2D:
	var a := Area2D.new()
	a.name = n
	a.position = rect.position + rect.size / 2
	_add(level, a)
	var shape := CollisionShape2D.new()
	shape.name = "CollisionShape2D"
	var r := RectangleShape2D.new()
	r.size = rect.size
	shape.shape = r
	_add(a, shape)
	return a

func _connect(from: Node, sig: String, method: String) -> void:
	from.connect(sig, Callable(level, method), CONNECT_PERSIST)

func _add(parent: Node, child: Node) -> void:
	parent.add_child(child)
	child.owner = level
