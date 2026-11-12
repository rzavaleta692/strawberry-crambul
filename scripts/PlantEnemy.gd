extends Area2D
# Planta lanzadora — se queda en su lugar y escupe semillas hacia el jugador
# cuando lo tiene cerca. Tocarla también quita una vida.

@export var seed_scene: PackedScene
@export var fire_interval := 2.2
## Distancia a la que empieza a disparar
@export var detect_range := 300.0
@export var seed_speed := 170.0

var player: Node2D = null
var _cooldown := 1.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemy")
	body_entered.connect(_on_body_entered)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")

func _physics_process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var to_player := player.global_position - global_position
	sprite.flip_h = to_player.x < 0
	_cooldown -= delta
	if _cooldown > 0.6:
		sprite.frame = 0
	if _cooldown <= 0.0 and abs(to_player.x) < detect_range and abs(to_player.y) < 160.0:
		_shoot(sign(to_player.x))
		_cooldown = fire_interval

func _shoot(dir: float) -> void:
	if seed_scene == null:
		return
	sprite.frame = 1
	var s: Area2D = seed_scene.instantiate()
	s.direction = Vector2(dir, 0)
	s.speed = seed_speed
	s.global_position = global_position + Vector2(dir * 22, -24)
	get_parent().add_child(s)

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage()
