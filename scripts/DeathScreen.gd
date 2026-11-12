extends Control
# Pantalla de muerte — jumpscare (cara del personaje que se acerca de golpe),
# luego su cuerpo, flash rojo + texto y vuelta al menú

const SHEETS := {
	"character1": "res://assets/sprites/characters/character1.png",
	"character2": "res://assets/sprites/characters/character2.png",
	"secret": "res://assets/sprites/characters/character_secret.png",
}

@onready var flash: ColorRect = $Flash
@onready var label: Label = $Label
@onready var timer: Timer = $Timer
@onready var body: TextureRect = $Body

func _ready() -> void:
	var who := SceneManager.last_dead_character
	match who:
		"character1":
			label.text = "Personaje 1 ha muerto.\nNo volverá."
		"character2":
			label.text = "Personaje 2 ha muerto.\nNo volverá."
		"secret":
			label.text = "La Carpintera ha muerto.\nNo volverá."
		_:
			label.text = "Has muerto.\nNo volverás."
	label.visible = false
	AudioManager.stop_music(0.1)
	AudioManager.play_sfx("jumpscare")

	var sheet: Texture2D = load(SHEETS.get(who, SHEETS["character1"]))
	var tex := AtlasTexture.new()
	tex.atlas = sheet
	tex.region = Rect2(0, 0, 48, 64)
	body.texture = tex

	# Jumpscare: la cara aparece enorme, roja y temblando
	# Centrado en la cara (filas 14-32 del cuadro de 64)
	body.pivot_offset = Vector2(body.size.x / 2, body.size.y * 0.36)
	body.modulate = Color(1, 0.25, 0.25)
	body.scale = Vector2(3, 3)
	var tween := create_tween()
	for i in 8:
		tween.tween_property(body, "position:x", body.position.x + (12 if i % 2 == 0 else -12), 0.04)
	tween.tween_property(body, "position:x", body.position.x, 0.04)
	tween.tween_callback(_show_body.bind(tex))

	timer.start(3.5)

func _show_body(tex: AtlasTexture) -> void:
	# El cuerpo queda tirado en el suelo (último cuadro de la hoja)
	var last_frame: int = tex.atlas.get_width() / 48 - 1
	tex.region = Rect2(last_frame * 48, 0, 48, 64)
	body.scale = Vector2.ONE
	body.modulate = Color(1, 1, 1)
	label.visible = true
	var tween := create_tween()
	tween.tween_property(flash, "color", Color(0.6, 0, 0, 0.0), 1.5) \
		.from(Color(1, 0, 0, 0.85))

func _on_timer_timeout() -> void:
	SceneManager.go_to_main_menu()
