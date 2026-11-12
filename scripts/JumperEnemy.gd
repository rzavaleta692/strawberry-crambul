extends Area2D
# Saltarín — se esconde en el fondo de un hueco y salta hacia arriba cada
# cierto tiempo. Antes de saltar sale polvo en la orilla del hueco para
# avisar. Hay que esperar a que baje para cruzar.

@export var jump_speed := 780.0
## Segundos que espera escondido entre un salto y otro
@export var wait_time := 1.8
## Retraso del primer salto (para que dos saltarines no vayan sincronizados)
@export var start_delay := 0.5
## Cuántos pixeles arriba de donde espera está la orilla del hueco (ahí sale el polvo)
@export var warn_height := 136.0
## Segundos de polvo antes de cada salto
@export var warn_time := 0.7

const GRAVITY := 1200.0
const HEAR_DISTANCE := 420.0

var _rest_y := 0.0
var _velocity := 0.0
var _jumping := false
var _wait := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var dust: CPUParticles2D = $Dust

func _ready() -> void:
	add_to_group("enemy")
	_rest_y = position.y
	_wait = start_delay
	sprite.visible = false
	dust.position.y = -warn_height
	dust.emitting = false
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not _jumping:
		_wait -= delta
		dust.emitting = _wait <= warn_time
		if _wait <= 0.0:
			_jumping = true
			_velocity = -jump_speed
			sprite.visible = true
			dust.emitting = false
			if _player_near():
				AudioManager.play_sfx("leap", -4.0)
		return
	_velocity += GRAVITY * delta
	sprite.position.y += _velocity * delta
	# Boca abierta al subir, cerrada al caer
	sprite.frame = 1 if _velocity < 0 else 0
	sprite.flip_v = _velocity > 0
	if _velocity > 0 and sprite.position.y >= 0.0:
		sprite.position.y = 0.0
		_jumping = false
		sprite.visible = false
		_wait = wait_time
	$CollisionShape2D.position.y = sprite.position.y

func _player_near() -> bool:
	var p := get_tree().get_first_node_in_group("player") as Node2D
	return p != null and p.global_position.distance_to(global_position + Vector2(0, -warn_height)) < HEAR_DISTANCE

func _on_body_entered(body: Node) -> void:
	if sprite.visible and body.is_in_group("player"):
		body.take_damage()
