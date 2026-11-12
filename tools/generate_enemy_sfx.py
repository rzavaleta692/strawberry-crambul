"""Genera los efectos de sonido de los enemigos (estilo chiptune).

Uso:  python3 tools/generate_enemy_sfx.py

Solo escribe stomp.wav, spit.wav y leap.wav en assets/audio/sfx/; no toca la
música ni los demás efectos (esos los hace tools/generate_audio.py).
"""
import math

from generate_audio import Noise, Track, sweep


def enemy_sfx():
    # Aplastar a una babosa: golpe grave y blando
    tr = Track(0.22)
    sweep(tr, 0, 0.2, 320, 70, "square", vol=0.3, duty=0.5)
    nz = Noise(21)
    tr.add(0, 0.08, lambda t, i: nz.sample(0.5), vol=0.3)
    tr.save("sfx/stomp.wav", 0.7)

    # Planta escupe una semilla: "ptu" corto
    tr = Track(0.14)
    nz = Noise(33)
    tr.add(0, 0.05, lambda t, i: nz.sample(0.1), vol=0.35)
    sweep(tr, 0.02, 0.1, 700, 300, "square", vol=0.2, duty=0.25)
    tr.save("sfx/spit.wav", 0.5)

    # Saltarín sale del hueco: chapoteo que sube
    tr = Track(0.3)
    nz = Noise(47)
    tr.add(0, 0.28, lambda t, i: nz.sample(0.7) * math.sin(math.pi * t / 0.28), vol=0.5, release=0.1)
    sweep(tr, 0, 0.25, 180, 520, "triangle", vol=0.2)
    tr.save("sfx/leap.wav", 0.5)


if __name__ == "__main__":
    enemy_sfx()
    print("Efectos de enemigos generados")
