extends CharacterBody2D
# Babosa — camina de un lado a otro sobre su plataforma y da la vuelta en
# paredes y orillas. Si la tocas te quita una vida; si le caes encima, la
# aplastas y rebotas.

@export var speed := 45.0
## -1 empieza caminando a la izquierda, 1 a la derecha
@export var start_direction := -1
@export var stomp_bounce := -460.0

const GRAVITY := 1960.0

var direction := -1
var dead := false
var _anim_time := 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var hit_area: Area2D = $HitArea
@onready var floor_ray: RayCast2D = $FloorRay

func _ready() -> void:
	add_to_group("enemy")
	direction = start_direction
	hit_area.body_entered.connect(_on_hit)

func _physics_process(delta: float) -> void:
	if dead:
		return
	velocity.y += GRAVITY * delta
	velocity.x = direction * speed
	floor_ray.position.x = direction * 14.0
	move_and_slide()
	if is_on_floor() and (is_on_wall() or not floor_ray.is_colliding()):
		direction = -direction
	_anim_time += delta
	sprite.frame = int(_anim_time * 4) % 2
	sprite.flip_h = direction < 0

func _on_hit(body: Node) -> void:
	if dead or not body.is_in_group("player") or body.dying:
		return
	# Le cayó encima: el jugador baja y sus pies están sobre la babosa
	if body.velocity.y > 0 and body.global_position.y < global_position.y - 10:
		_squash(body)
	else:
		body.take_damage()

func _squash(player: Node) -> void:
	dead = true
	player.velocity.y = stomp_bounce
	AudioManager.play_sfx("stomp")
	hit_area.set_deferred("monitoring", false)
	collision_layer = 0
	var tween := create_tween()
	tween.tween_property(sprite, "scale", Vector2(1.4, 0.3), 0.12)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.25)
	tween.tween_callback(queue_free)
