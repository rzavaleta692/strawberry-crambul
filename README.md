# Strawberry Crambul

Videojuego híbrido (plataformas + shooter + terror) con pixel art estilo Mario Bros.  
Desarrollado en **Godot 4.7** con **GDScript**.

¿Quieres cambiar algo y no sabes dónde? Revisa la
[documentación técnica](docs/DOCUMENTACION_TECNICA.md).

## Estructura del proyecto

```
strawberry_crambul/
├── project.godot
├── assets/
│   ├── sprites/
│   │   ├── characters/     # Personaje 1, 2, secreto, muertos
│   │   ├── enemies/        # Fantasmas de personajes caídos
│   │   ├── ui/             # HUD, vidas, menú
│   │   └── tiles/          # Tilesets nivel 1 y nivel 2
│   ├── audio/              # SFX / música (placeholders)
│   └── fonts/
├── scenes/
│   ├── ui/                 # MainMenu, CharacterSelect, HUD, DeathScreen, finales
│   ├── levels/             # Level1 (plataformas), Level2 (top-down)
│   └── entities/           # Personajes, GhostEnemy, Collectible, Projectile
└── scripts/                # GDScript — lógica separada de los assets
```

## Controles

| Acción        | Teclado         |
|---------------|-----------------|
| Moverse       | WASD / Flechas  |
| Saltar        | Espacio         |
| Planear       | Mantener Espacio en el aire (Personaje 1) |
| Disparar      | Click izquierdo (Personaje 2) |
| Pausa         | Esc (Continuar / Salir al menú) |

## Mecánicas principales

- **Muerte permanente**: morir guarda el estado en disco (`user://save.json`). El personaje no vuelve a estar disponible.
- **Corazones por intento**: cada personaje tiene 3 corazones para todo su intento. Se guardan en el momento en que se pierde uno, así que salir al menú o cerrar el juego **no los devuelve**; al volver se empieza desde el inicio del nivel con los que quedaban. La tarjeta de selección muestra cuántos le quedan.
- **Fantasmas**: si un personaje muere, aparece como enemigo semitransparente en el nivel del otro personaje.
- **Personaje secreto**: se desbloquea recogiendo todos los coleccionables ocultos.
- **Final Malo**: se activa cuando todos los personajes están muertos.
- **Final Verdadero**: requiere todos los coleccionables + completar el juego con el personaje secreto.
- **Nueva partida**: aparece en la esquina inferior izquierda del menú (y en el Final Malo) cuando todos los personajes han muerto. Reinicia muertes, corazones y coleccionables.

## Fases de desarrollo

| Fase | Contenido |
|------|-----------|
| 1 | ✅ Estructura del proyecto, Autoloads, SceneManager |
| 2 | Menú principal + selección de personajes con persistencia |
| 3 | ✅ Personaje 1 + Nivel 1 completo (pixel art placeholder) |
| 4 | Personaje 2 + Nivel 2 completo |
| 5 | Sistema de fantasmas + coleccionables |
| 6 | DeathScreen (jumpscare) + ambos finales |
| 7 | Personaje secreto |
| 8 | Pulido: música, SFX, efectos visuales |

## Nivel 1 (pixel art)

Recorrido rural según el guion: tutorial con letreros, abismos que se cruzan
planeando con el paraguas (dura 1.5 s y se recarga al tocar suelo), pinchos,
escalada en tablones, 3 faroles de control (al perder una vida se reaparece en
el último encendido) y una zona elevada al final donde se ve la casa de la
carpintera y se descubre que el puente desapareció.

- **Coleccionable oculto**: una fresa dentro de una cueva escondida en la colina,
  sobre los pinchos. Se entra caminando por el tablón pegado a la pared.
- **Fantasmas**: cada personaje muerto (que no sea el que se está jugando) aparece
  como fantasma que persigue al jugador.
- El nivel está en `scenes/levels/Level1.tscn` con un `TileMapLayer` (`Ground`)
  que se puede pintar en el editor con `assets/tilesets/level1_tileset.tres`.
- `tools/build_level1.gd` regenera el nivel desde cero
  (`godot --headless --path . --script res://tools/build_level1.gd`).
  **Sobrescribe los cambios hechos a mano** en `Level1.tscn`.
- `tools/generate_pixel_art.py` regenera los sprites placeholder (requiere Pillow).

## Menús (pixel art, estilo de la propuesta en PDF)

Todos los menús usan el tema `assets/ui/pixel_theme.tres` (botones, paneles crema
y las variaciones `PillButton` y `LetterButton`) y el fondo de día compartido
`scenes/ui/MenuBackground.tscn`. Se navegan con mouse o con flechas + Enter.

- **Menú principal**: título blanco/rosa y las opciones escritas sobre la carta
  rosa. **Opciones** permite apagar/prender música y sonido (se guarda en
  `user://settings.cfg`).
- **Selección de personaje**: tarjetas rosas con **Jugar** y **Hoja**; dos tarjetas
  "Por definir" para los personajes que faltan. Un personaje muerto muestra su
  cadáver y solo deja ver su Hoja ("Tuvo su oportunidad"). El secreto aparece
  cuando se desbloquea. Los textos de la Hoja están en `CharacterSelect.gd`.
- **Pantalla de muerte**: jumpscare con la cara del personaje y después su cuerpo.

## Música y sonido

`scripts/AudioManager.gd` (autoload) toca la música de fondo con fundido y los
efectos; todos los botones suenan solos al pasar el mouse y al presionarlos.
La música y efectos son chiptune generados por `tools/generate_audio.py`
(`assets/audio/music/*.wav` y `assets/audio/sfx/*.wav`); se pueden reemplazar con
el mismo nombre. Si se cambia un archivo de música, en su `.import` debe quedar
`edit/loop_mode=2` para que se repita.

## Assets pendientes

Los sprites son **placeholders** pixel art generados por `tools/generate_pixel_art.py` — el equipo los reemplaza (mismo nombre y tamaño; los personajes son hojas de 6 cuadros de 48×64: quieto, correr A, correr B, salto, planeo, muerto) con sus diseños de Krita/IbisPaint X.

### Tamaños para dibujar

El juego corre a **640×360** y se escala por múltiplos enteros a la ventana
(1280×720 por defecto), así que cada píxel del sprite se ve nítido.

| Qué | Tamaño del PNG |
|---|---|
| Personaje (hoja de 6 cuadros) | 288×64 (cada cuadro 48×64; el personaje ocupa ~32×48, con los pies en la parte de abajo) |
| Tiles del piso (`level1_tiles.png`) | 128×32 (4 tiles de 32×32: pasto, tierra, tablón, tierra oscura) |
| Pinchos | 32×32 |
| Fondos (cielo, nubes, colinas) | 640×360, se repiten a lo ancho |

**Plantilla:** en `docs/arte/` está `plantilla_personaje.png` (288×64, tamaño real
para dibujar encima en una capa nueva), `plantilla_personaje_guia.png` (la misma
a 4× con la explicación de cada guía) y `referencia_personajes.png` (los sprites
actuales en grande). Se regeneran con `python3 tools/generate_art_template.py`.

Los sprites actuales de los personajes (`tools/characters_hd.py`) se basan en los
bocetos de la propuesta: el Personaje 1 con pelo largo, blusa de manga abombada,
falda larga, carta y paraguas; el Personaje 2 con chongo y mangas anchas.

Consejo: dibujar a ese tamaño exacto en Krita con un pincel de píxel, o dibujar
más grande y reducir con *vecino más cercano* para que no se vea borroso. Usar
siempre PNG con transparencia.  
Carpetas de destino:
- `assets/sprites/characters/` — sprites de personajes y versiones muertas
- `assets/sprites/enemies/` — sprites de fantasmas
- `assets/sprites/tiles/` — tilesets por nivel
- `assets/audio/` — SFX y música
