extends Node
# Autoload — Música de fondo y efectos de sonido
# También da sonido a todos los botones del juego automáticamente.

const SETTINGS_PATH := "user://settings.cfg"
const MUSIC_DB := -6.0
const SILENT_DB := -60.0

const MUSIC := {
	"menu": "res://assets/audio/music/menu.wav",
	"level1": "res://assets/audio/music/level1.wav",
	"bad_ending": "res://assets/audio/music/bad_ending.wav",
	"true_ending": "res://assets/audio/music/true_ending.wav",
}
const SFX := {
	"jump": "res://assets/audio/sfx/jump.wav",
	"glide": "res://assets/audio/sfx/glide.wav",
	"hurt": "res://assets/audio/sfx/hurt.wav",
	"collect": "res://assets/audio/sfx/collect.wav",
	"checkpoint": "res://assets/audio/sfx/checkpoint.wav",
	"ui_hover": "res://assets/audio/sfx/ui_hover.wav",
	"ui_click": "res://assets/audio/sfx/ui_click.wav",
	"death": "res://assets/audio/sfx/death.wav",
	"jumpscare": "res://assets/audio/sfx/jumpscare.wav",
	"bridge": "res://assets/audio/sfx/bridge.wav",
	"stomp": "res://assets/audio/sfx/stomp.wav",
	"spit": "res://assets/audio/sfx/spit.wav",
	"leap": "res://assets/audio/sfx/leap.wav",
}

var music_on := true
var sfx_on := true

var _music: AudioStreamPlayer
var _current := ""
var _fade: Tween
var _sfx_players: Array[AudioStreamPlayer] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_settings()
	_music = AudioStreamPlayer.new()
	_music.finished.connect(_on_music_finished)
	add_child(_music)
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_sfx_players.append(p)
	get_tree().node_added.connect(_on_node_added)

# ---------------------------------------------------------------- música
func play_music(track: String, fade := 0.8) -> void:
	if track == _current and _music.playing:
		return
	_current = track
	if _fade:
		_fade.kill()
	_fade = create_tween()
	if _music.playing:
		_fade.tween_property(_music, "volume_db", SILENT_DB, fade * 0.5)
	_fade.tween_callback(func():
		_music.stream = load(MUSIC[track])
		_music.volume_db = SILENT_DB
		_music.play())
	_fade.tween_property(_music, "volume_db", _music_target_db(), fade * 0.5)

func stop_music(fade := 0.8) -> void:
	_current = ""
	if _fade:
		_fade.kill()
	_fade = create_tween()
	_fade.tween_property(_music, "volume_db", SILENT_DB, fade)
	_fade.tween_callback(_music.stop)

func _on_music_finished() -> void:
	# La música de fondo se repite
	if _current != "":
		_music.play()

func _music_target_db() -> float:
	return MUSIC_DB if music_on else SILENT_DB

# ---------------------------------------------------------------- efectos
func play_sfx(sfx_name: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not sfx_on or not SFX.has(sfx_name):
		return
	for p in _sfx_players:
		if not p.playing:
			p.stream = load(SFX[sfx_name])
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		node.pressed.connect(play_sfx.bind("ui_click"))
		node.mouse_entered.connect(_on_button_hover.bind(node))

func _on_button_hover(button: BaseButton) -> void:
	if not button.disabled and button.modulate.a > 0.0:
		play_sfx("ui_hover", -4.0)

# ---------------------------------------------------------------- opciones
func set_music_on(value: bool) -> void:
	music_on = value
	if _fade:
		_fade.kill()
	_music.volume_db = _music_target_db()
	_save_settings()

func set_sfx_on(value: bool) -> void:
	sfx_on = value
	_save_settings()

func _load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS_PATH) == OK:
		music_on = cfg.get_value("audio", "music_on", true)
		sfx_on = cfg.get_value("audio", "sfx_on", true)

func _save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "music_on", music_on)
	cfg.set_value("audio", "sfx_on", sfx_on)
	cfg.save(SETTINGS_PATH)
