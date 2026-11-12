extends Area2D
# Semilla que escupe la planta lanzadora — se rompe al chocar con el suelo
# o una pared, y quita una vida si toca al jugador.

var direction := Vector2.LEFT
var speed := 170.0
var _life := 4.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta
	rotation += 8.0 * delta * sign(direction.x)
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		body.take_damage()
	elif body.is_in_group("enemy"):
		return
	queue_free()
