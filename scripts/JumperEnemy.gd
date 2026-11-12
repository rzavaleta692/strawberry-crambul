extends Area2D
# Saltarín — se esconde en el fondo de un hueco y salta hacia arriba cada
# cierto tiempo. Hay que esperar a que baje para cruzar.

@export var jump_speed := 780.0
## Segundos que espera escondido entre un salto y otro
@export var wait_time := 1.8
## Retraso del primer salto (para que dos saltarines no vayan sincronizados)
@export var start_delay := 0.5

const GRAVITY := 1200.0

var _rest_y := 0.0
var _velocity := 0.0
var _jumping := false
var _wait := 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemy")
	_rest_y = position.y
	_wait = start_delay
	visible = false
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if not _jumping:
		_wait -= delta
		if _wait <= 0.0:
			_jumping = true
			_velocity = -jump_speed
			visible = true
		return
	_velocity += GRAVITY * delta
	position.y += _velocity * delta
	# Boca abierta al subir, cerrada al caer
	sprite.frame = 1 if _velocity < 0 else 0
	sprite.flip_v = _velocity > 0
	if _velocity > 0 and position.y >= _rest_y:
		position.y = _rest_y
		_jumping = false
		visible = false
		_wait = wait_time

func _on_body_entered(body: Node) -> void:
	if visible and body.is_in_group("player"):
		body.take_damage()
