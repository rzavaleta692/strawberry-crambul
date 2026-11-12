extends CharacterBody2D
# Personaje 1 — Paraguas
# Movimiento lateral + vuelo temporal (caída lenta con paraguas).
# También lo usa el Personaje Secreto (CharacterSecret.gd) con otros valores.

signal lives_changed(current: int)

@export var character_id := "character1"
@export var speed := 220.0
@export var jump_force := -640.0
@export var can_glide := true
## Segundos que dura el vuelo con paraguas antes de cerrarse (se recarga al tocar suelo)
@export var glide_time := 1.5
@export var glide_fall_speed := 70.0
## Si el personaje cae por debajo de esta Y, cayó a un abismo
@export var fall_limit := 680.0

const GRAVITY := 1960.0
const INVULNERABLE_TIME := 1.5

enum Frame { IDLE_A, IDLE_B, RUN_A, RUN_B, RUN_C, JUMP, GLIDE, FALL, LAND, DEAD }

var lives := 3
var is_gliding := false
var glide_left := 0.0
var respawn_point := Vector2.ZERO
var controls_enabled := true
var invulnerable := false
var dying := false
var hud: Node = null
var _land_timer := 0.0
const LAND_DURATION := 0.12
var _anim_time := 0.0


@onready var sprite: Sprite2D = $Sprite2D
# Posición X del sprite mirando a la derecha; se refleja al voltear para que
# el dibujo no se desfase de la caja de colisión
@onready var _sprite_x := sprite.position.x

func _ready() -> void:
	add_to_group("player")
	# Los corazones del intento se conservan aunque se salga del nivel
	lives = GameData.get_lives(character_id)
	respawn_point = global_position
	glide_left = glide_time
	# HUD se busca en el nivel padre
	hud = get_tree().get_first_node_in_group("hud")
	if hud:
		hud.update_lives(lives)

func _physics_process(delta: float) -> void:
	if dying:
		return

	var on_floor := is_on_floor()
	if on_floor:
		glide_left = glide_time

	var jump_held := controls_enabled and Input.is_action_pressed("jump")
	var was_gliding := is_gliding
	is_gliding = can_glide and jump_held and not on_floor and velocity.y > 0 and glide_left > 0
	if is_gliding and not was_gliding:
		AudioManager.play_sfx("glide")
	if is_gliding:
		glide_left -= delta
		velocity.y = min(velocity.y + GRAVITY * delta, glide_fall_speed)
	elif not on_floor:
		velocity.y += GRAVITY * delta

	if controls_enabled and Input.is_action_just_pressed("jump") and on_floor:
		velocity.y = jump_force
		AudioManager.play_sfx("jump")

	var direction := Input.get_axis("move_left", "move_right") if controls_enabled else 0.0
	velocity.x = direction * speed

	var was_on_floor := is_on_floor()

	move_and_slide()

	if not was_on_floor and is_on_floor():
		_land_timer = LAND_DURATION

	_animate(delta, direction)

	if global_position.y > fall_limit:
		take_damage(true)

func _animate(delta: float, direction: float) -> void:
	if direction != 0:
		sprite.flip_h = direction < 0
		sprite.position.x = -_sprite_x if sprite.flip_h else _sprite_x

	if _land_timer > 0.0:
		_land_timer -= delta
		sprite.frame = Frame.LAND
	elif is_gliding:
		sprite.frame = Frame.GLIDE
	elif not is_on_floor():
		sprite.frame = Frame.JUMP if velocity.y < 0 else Frame.FALL
	elif direction != 0:
		_anim_time += delta
		# Ciclo de 3 frames de caminata, ~8 fps
		var step := int(_anim_time * 8) % 3
		sprite.frame = [Frame.RUN_A, Frame.RUN_B, Frame.RUN_C][step]
	else:
		_anim_time += delta
		# Respiración: 2 frames, ~2 fps (lento)
		sprite.frame = Frame.IDLE_A if int(_anim_time * 2) % 2 == 0 else Frame.IDLE_B

func take_damage(ignore_invulnerability := false) -> void:
	if dying or (invulnerable and not ignore_invulnerability):
		return
	lives -= 1
	lives_changed.emit(lives)
	if lives > 0:
		# Se guarda en el momento: cerrar el juego no devuelve el corazón
		GameData.set_lives(character_id, lives)
	if hud:
		hud.update_lives(lives)
	_shake_camera()
	if lives <= 0:
		_die()
	else:
		AudioManager.play_sfx("hurt")
		_respawn()

func _shake_camera(strength := 5, duration := 0.3) -> void:
	# Pequeño temblor de pantalla al recibir daño
	var cam: Camera2D = null
	for child in get_children():
		if child is Camera2D:
			cam = child
	if cam == null:
		return
	var base := cam.offset
	var steps := 6
	var tween := create_tween()
	for i in steps:
		var jolt := Vector2(randi_range(-strength, strength), randi_range(-strength, strength))
		tween.tween_property(cam, "offset", base + jolt, duration / (steps + 1))
	tween.tween_property(cam, "offset", base, duration / (steps + 1))

func _respawn() -> void:
	global_position = respawn_point
	velocity = Vector2.ZERO
	_start_invulnerability()

func _start_invulnerability() -> void:
	invulnerable = true
	var tween := create_tween().set_loops(6)
	tween.tween_property(sprite, "modulate:a", 0.2, 0.125)
	tween.tween_property(sprite, "modulate:a", 1.0, 0.125)
	await get_tree().create_timer(INVULNERABLE_TIME, false).timeout
	invulnerable = false
	sprite.modulate.a = 1.0

func _die() -> void:
	# Se muestra el cuerpo unos segundos antes del jumpscare
	dying = true
	velocity = Vector2.ZERO
	sprite.frame = Frame.DEAD
	sprite.modulate = Color(1, 0.6, 0.6)
	AudioManager.stop_music(0.3)
	AudioManager.play_sfx("death")
	GameData.kill_character(character_id)
	await get_tree().create_timer(1.5, false).timeout
	SceneManager.go_to_death_screen(character_id)
