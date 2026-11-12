extends Area2D
# Cuervo — vuela de ida y vuelta en línea recta, subiendo y bajando un poco.
# Si lo tocas te quita una vida.

@export var speed := 70.0
## Distancia en pixeles que recorre hacia cada lado desde donde se coloca
@export var flight_range := 120.0
@export var bob_height := 10.0
## -1 empieza volando a la izquierda, 1 a la derecha
@export var start_direction := -1

var direction := -1
var _origin := Vector2.ZERO
var _time := 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("enemy")
	direction = start_direction
	_origin = position
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	_time += delta
	position.x += direction * speed * delta
	if abs(position.x - _origin.x) > flight_range:
		position.x = _origin.x + sign(position.x - _origin.x) * flight_range
		direction = -direction
	position.y = _origin.y + round(sin(_time * 3.0) * bob_height)
	sprite.frame = int(_time * 6) % 2
	sprite.flip_h = direction < 0

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage()
