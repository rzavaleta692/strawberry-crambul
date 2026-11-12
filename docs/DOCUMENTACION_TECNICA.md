# Documentación técnica — Strawberry Crambul

Guía rápida para saber **dónde ir para cambiar cada cosa** del juego.
Si solo quieres saber de qué trata el juego, lee el `README.md`.

- Motor: **Godot 4.7** (todo el equipo debe usar 4.7; si alguien abre y guarda
  con una versión más vieja, Godot reescribe archivos y pueden salir errores).
- Lenguaje: GDScript.
- Resolución: el juego se dibuja a **640x360** y se escala a la ventana
  (1280x720) en múltiplos enteros, para que el pixel art se vea nítido.

---

## 1. Mapa del proyecto

| Carpeta | Qué hay |
|---|---|
| `scenes/ui/` | Pantallas: menú principal, selección de personaje, HUD, pantalla de muerte, finales |
| `scenes/levels/` | `Level1.tscn` (plataformas) y `Level2.tscn` (top-down) |
| `scenes/entities/` | Personajes, enemigos, pinchos, faroles, letreros, coleccionables, proyectiles |
| `scripts/` | Toda la lógica. Cada escena usa el script del mismo nombre |
| `assets/sprites/` | Imágenes: `characters/`, `enemies/`, `tiles/`, `props/`, `backgrounds/`, `ui/` |
| `assets/audio/` | `music/` (música) y `sfx/` (efectos) |
| `assets/ui/pixel_theme.tres` | Tema de todos los botones y paneles |
| `assets/tilesets/level1_tileset.tres` | Tiles del Nivel 1 (pasto, tierra, tablón) |
| `tools/` | Scripts que generan el nivel, los sprites y los sonidos de prueba |
| `docs/arte/` | Plantillas y referencias para dibujar (Godot no las carga) |

### Autoloads (siempre están cargados)

Se configuran en *Proyecto → Configuración del proyecto → Globals*.

| Nombre | Archivo | Para qué sirve |
|---|---|---|
| `GameData` | `scripts/GameData.gd` | Partida guardada: muertes, vidas, fresas encontradas, personaje secreto |
| `SceneManager` | `scripts/SceneManager.gd` | Cambiar de pantalla (`go_to_level1()`, `go_to_death_screen()`, …) |
| `AudioManager` | `scripts/AudioManager.gd` | Música y efectos (`play_music("level1")`, `play_sfx("jump")`) |

La partida se guarda en `user://save.json`. En Linux está en
`~/.local/share/godot/app_userdata/Strawberry Crambul/`; en Windows en
`%APPDATA%\Godot\app_userdata\Strawberry Crambul\`. Para empezar de cero se
puede borrar ese archivo o usar **Nueva partida** en el menú.

---

## 2. "Quiero cambiar…" → dónde ir

### Personaje y movimiento

| Quiero cambiar… | Dónde |
|---|---|
| Velocidad, fuerza de salto, tiempo de paraguas | `scenes/entities/Character1.tscn` → Inspector (variables `speed`, `jump_force`, `glide_time`, `glide_fall_speed`) o los valores por defecto en `scripts/Character1.gd` |
| Animaciones del personaje (qué cuadro se usa) | `scripts/Character1.gd`, función `_animate()` y el `enum Frame` |
| Sprite del personaje | `assets/sprites/characters/character1.png` (cuadros de 48x64 en una fila; si cambias el número de cuadros, cambia `hframes` en `Character1.tscn` y el `enum Frame`) |
| Tamaño de la caja de colisión | `Character1.tscn` → nodo `CollisionShape2D` |
| Qué pasa al recibir daño o morir | `scripts/Character1.gd`, funciones `take_damage()`, `_respawn()` y `_die()` |
| Personaje 2 (dispara) | `scripts/Character2.gd` y `scenes/entities/Character2.tscn` |
| Personaje secreto | `scenes/entities/CharacterSecret.tscn` (reutiliza `Character1.gd` con otros valores) |

### Vidas, guardado y reglas

| Quiero cambiar… | Dónde |
|---|---|
| Número de corazones | `scripts/GameData.gd` → `MAX_LIVES` |
| Cuántas fresas desbloquean al personaje secreto | `scripts/GameData.gd` → `_check_secret_unlock()` |
| Qué personajes cuentan para el Final Malo | `scripts/GameData.gd` → `all_dead()` |
| Tiempo de invulnerabilidad tras un golpe | `scripts/Character1.gd` → `INVULNERABLE_TIME` |

### Pantallas y menús

| Quiero cambiar… | Dónde |
|---|---|
| Menú principal (botones, carta) | `scenes/ui/MainMenu.tscn` + `scripts/MainMenu.gd` |
| Selección de personaje: nombres, habilidad, historia de la Hoja | `scripts/CharacterSelect.gd` → diccionario `CHARACTERS` |
| Tarjetas de selección (posiciones, botones) | `scenes/ui/CharacterSelect.tscn` |
| Texto de la pantalla de muerte | `scripts/DeathScreen.gd` → `_ready()` |
| Duración o efecto del susto (jumpscare) | `scripts/DeathScreen.gd` (tween del susto y el `Timer`) |
| Corazones y mensajes durante el nivel, menú de pausa | `scenes/ui/HUD.tscn` + `scripts/HUD.gd` (`show_message()`, `update_lives()`) |
| Colores y estilo de botones | `assets/ui/pixel_theme.tres` y las imágenes `assets/sprites/ui/button_*.png` |
| Finales | `scenes/ui/BadEnding.tscn`, `scenes/ui/TrueEnding.tscn` y sus scripts |

### Retratos: usar imágenes en lugar de sprites

Hoy la tarjeta de selección, la **Hoja** y la pantalla de muerte **no** usan
una imagen propia: recortan un cuadro de 48x64 de la hoja de sprites del juego
(`assets/sprites/characters/character1.png`, etc.). Para usar un dibujo
(retrato) hay que cambiar dos scripts.

**1. Guardar las imágenes.** Crear la carpeta `assets/sprites/portraits/` y
guardar ahí un retrato por personaje, en proporción **3:4** (recomendado
384x512):

| Archivo | Para qué |
|---|---|
| `character1.png` | Personaje vivo |
| `character1_dead.png` | Personaje muerto (opcional) |

Lo mismo con `character2` y `secret`. Los cuadros donde se muestran ya están
en 3:4: tarjeta 96x128, Hoja 144x192 y pantalla de muerte 192x256.

**2. Selección de personaje y Hoja — `scripts/CharacterSelect.gd`.** Toda la
imagen sale de la función `_portrait(id, dead)`; la usan las tarjetas
(`_refresh_ui()`) y la Hoja (`_on_sheet_pressed()`). Cambiarla para que cargue
el retrato si existe, y si no, siga usando el sprite:

```gdscript
func _portrait(id: String, dead: bool) -> Texture2D:
	var base := "res://assets/sprites/portraits/" + id
	if dead and ResourceLoader.exists(base + "_dead.png"):
		return load(base + "_dead.png")
	if ResourceLoader.exists(base + ".png"):
		return load(base + ".png")
	# Sin retrato: cuadro de la hoja de sprites (como antes)
	var tex := AtlasTexture.new()
	tex.atlas = load(CHARACTERS[id]["sheet"])
	tex.region = Rect2((FRAME_DEAD if dead else FRAME_IDLE) * 48, 0, 48, 64)
	return tex
```

**3. Pantalla de muerte — `scripts/DeathScreen.gd`.** En `_ready()` se arma
la cara del susto (`tex.region = Rect2(0, 0, 48, 64)`) y en `_show_body()` el
cuerpo (`tex.region = Rect2(5 * 48, 0, 48, 64)`). Ahí se cambia
`body.texture = ...` por el retrato, por ejemplo cargando
`res://assets/sprites/portraits/character1.png` para el susto y
`character1_dead.png` para el cuerpo, con la misma idea de "si no existe, usar
el sprite". `_show_body()` recibe la textura como parámetro; si se cambia a
retrato, conviene pasarle el `id` del personaje en su lugar.

**4. Que no se vean pixelados.** El proyecto dibuja todo en modo "Nearest"
(pixel art). Si el retrato es un dibujo normal, en el `TextureRect` que lo
muestra (`Portrait` de cada tarjeta, `Sheet/Portrait` y `Body` en la pantalla
de muerte) poner **Texture → Filter = Linear** en el Inspector. Si el retrato
también es pixel art, dejarlo como está.

> **Detalle actual:** la hoja nueva de Personaje 1 tiene 10 cuadros y el
> cuadro de muerto ahora es el **9**, pero `CharacterSelect.gd`
> (`FRAME_DEAD := 5`) y `DeathScreen.gd` (`5 * 48`) siguen usando el 5, que
> ahora es el de salto. Si se queda el sprite como respaldo, hay que corregir
> ese número (Personaje 2 y el secreto siguen teniendo 6 cuadros, su muerto es
> el 5).

### Nivel 1

| Quiero cambiar… | Dónde |
|---|---|
| Pintar o borrar suelo y plataformas | Abrir `Level1.tscn` → nodo `Ground` (TileMapLayer) → pintar con el TileSet |
| Mover pinchos, faroles, letreros, fantasmas | `Level1.tscn` → grupos `Hazards`, `Checkpoints`, `Signs`, `GhostSpawns` |
| Texto de un letrero | Seleccionar el letrero en `Level1.tscn` → Inspector → `text` |
| Texto de inicio o escena del puente | `scripts/Level1.gd` → `INTRO_TEXT` y `BRIDGE_TEXTS` |
| Dónde aparece el jugador | `Level1.tscn` → nodo `PlayerStart` |
| Límites de la cámara | `scripts/Level1.gd` → `level_size` |
| Altura a la que cuenta como caída al abismo | `Character1.gd` → `fall_limit` |
| Fondo (cielo, nubes, colinas) | Imágenes en `assets/sprites/backgrounds/`; capas `Clouds`, `HillsFar`, `HillsNear` del nivel |

> **Ojo:** `Level1.tscn` se puede generar con `tools/build_level1.gd`. Si
> alguien vuelve a correr ese script, **se borran los cambios hechos a mano**
> en el editor. Si editas el nivel a mano, avisa al equipo; si prefieres el
> script, haz el cambio en `tools/build_level1.gd` y vuelve a generar.

### Enemigos y trampas

| Quiero cambiar… | Dónde |
|---|---|
| Pinchos (daño al tocar) | `scenes/entities/Spikes.tscn` + `scripts/Hazard.gd` |
| Fantasmas (personajes muertos) | `scenes/entities/GhostEnemy.tscn` + `scripts/GhostEnemy.gd` (`SPEED`, `DETECT_RANGE`) |

| Babosa (camina, se aplasta al caerle encima) | `scenes/entities/SlimeEnemy.tscn` + `scripts/SlimeEnemy.gd` (`speed`, `start_direction`, `stomp_bounce`) |
| Cuervo (vuela de ida y vuelta) | `scenes/entities/CrowEnemy.tscn` + `scripts/CrowEnemy.gd` (`speed`, `flight_range`, `bob_height`) |
| Saltarín (salta desde un hueco) | `scenes/entities/JumperEnemy.tscn` + `scripts/JumperEnemy.gd` (`jump_speed`, `wait_time`, `start_delay`) |
| Planta lanzadora (escupe semillas) | `scenes/entities/PlantEnemy.tscn` + `scripts/PlantEnemy.gd` (`fire_interval`, `detect_range`, `seed_speed`) |
| Semilla de la planta | `scenes/entities/EnemySeed.tscn` + `scripts/EnemySeed.gd` |
| Dónde está cada enemigo en el Nivel 1 | `Level1.tscn` → grupo `Enemies` (moverlos en el editor) o la lista de `_build_enemies()` en `tools/build_level1.gd` |
| Sprites de los enemigos | `assets/sprites/enemies/` (hojas de 2 cuadros; ver tamaños en `tools/generate_enemies.py`) |

Los valores entre paréntesis se cambian por enemigo en el **Inspector**
(seleccionando el enemigo dentro de `Level1.tscn`) o para todos en su script.
Todos quitan una vida con `take_damage()` al tocar al jugador.

### Sonido

| Quiero cambiar… | Dónde |
|---|---|
| Una canción o un efecto | Reemplazar el `.wav` en `assets/audio/music/` o `assets/audio/sfx/` con el mismo nombre |
| Agregar un efecto nuevo | Ponerlo en `assets/audio/sfx/` y agregarlo al diccionario `SFX` de `scripts/AudioManager.gd`; luego `AudioManager.play_sfx("nombre")` |
| Volumen general de la música | `scripts/AudioManager.gd` → `MUSIC_DB` |

### Controles

*Proyecto → Configuración del proyecto → Mapa de entrada*: acciones
`move_left`, `move_right`, `move_up`, `move_down` y `jump`. La pausa (Esc) se
maneja en `scripts/HUD.gd`.

---

## 3. Cosas que conviene saber

- **Grupos:** el jugador está en el grupo `player` y los enemigos en `enemy`.
  Las trampas y enemigos revisan `body.is_in_group("player")` y llaman a
  `body.take_damage()`. Si haces un enemigo nuevo, sigue esa idea.
- **Coordenadas del Nivel 1:** los tiles miden 32x32. En los scripts de
  `tools/` las posiciones están en tiles (por ejemplo, fila 17 = suelo inicial).
- **Pixel art nítido:** el filtro de texturas está en "Nearest" para todo el
  proyecto. No cambies imágenes a tamaños con decimales.
- **Archivos `.import` y `.uid`:** Godot los crea solo. Súbelos al repositorio
  junto con la imagen o script al que pertenecen.

---

## 4. Herramientas (`tools/`)

Se corren desde la carpeta del proyecto. Los scripts de Python necesitan
Pillow (`pip install pillow`).

| Comando | Qué hace | Cuidado |
|---|---|---|
| `godot --headless --path . --script res://tools/build_level1.gd` | Regenera `Level1.tscn` y el TileSet | Borra cambios hechos a mano en el nivel |
| `python3 tools/generate_pixel_art.py` | Regenera **todos** los sprites de prueba | **Sobrescribe** personajes, menús y tiles, incluido el arte del equipo. Úsalo solo si sabes qué vas a reemplazar |
| `python3 tools/generate_enemies.py` | Regenera los sprites de los enemigos | Solo escribe en `assets/sprites/enemies/`; sobrescribe dibujos de enemigos del equipo |
| `python3 tools/generate_audio.py` | Regenera los sonidos de prueba | Sobrescribe los `.wav` |

Para cambiar una imagen sin herramientas: ábrela en Krita o IbisPaint X,
dibuja encima y guárdala **con el mismo nombre y tamaño**. Las plantillas para
personajes están en `docs/arte/`.

---

## 5. Cómo subir cambios (Git)

1. Actualiza tu copia: `git switch main` y `git pull`.
2. Crea una rama para lo que vas a hacer: `git switch -c nombre-de-tu-cambio`.
3. Trabaja en Godot 4.7 y prueba el juego.
4. Guarda y sube: `git add -A`, `git commit -m "Qué cambiaste"`, `git push -u origin nombre-de-tu-cambio`.
5. En GitHub abre un **Pull Request** hacia `main` para que el equipo lo revise.

Para no pisarse: avisen en el grupo qué archivos va a tocar cada quien. Dos
personas editando la misma escena (`.tscn`) al mismo tiempo casi siempre
termina en conflictos difíciles de arreglar.
