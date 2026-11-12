"""Genera los sprites pixel art placeholder de los enemigos del Nivel 1.

Uso:  python3 tools/generate_enemies.py

Solo escribe en assets/sprites/enemies/ (no toca personajes ni menús).
Cada sprite es una hoja horizontal de 2 cuadros, dibujada a 1x y escalada x2
como el resto del arte. El equipo puede reemplazar cualquiera manteniendo el
mismo nombre y tamaño:

  slime.png    2 cuadros de 32x24   (caminante)
  crow.png     2 cuadros de 32x24   (pájaro)
  jumper.png   2 cuadros de 24x28   (salta desde abajo)
  plant.png    2 cuadros de 32x32   (lanzador)
  seed.png     1 cuadro de 12x12     (proyectil de la planta)
"""
import os

from PIL import Image

DEST = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sprites", "enemies")
SCALE = 2
OUTLINE = (25, 18, 28, 255)


class Canvas:
    def __init__(self, w, h):
        self.img = Image.new("RGBA", (w, h), (0, 0, 0, 0))
        self.w, self.h = w, h

    def px(self, x, y, c):
        if 0 <= x < self.w and 0 <= y < self.h:
            self.img.putpixel((x, y), c if len(c) == 4 else (*c, 255))

    def rect(self, x0, y0, x1, y1, c):
        for y in range(y0, y1 + 1):
            for x in range(x0, x1 + 1):
                self.px(x, y, c)

    def ellipse(self, cx, cy, rx, ry, c):
        for y in range(cy - ry, cy + ry + 1):
            for x in range(cx - rx, cx + rx + 1):
                if ((x - cx) / (rx + 0.5)) ** 2 + ((y - cy) / (ry + 0.5)) ** 2 <= 1.0:
                    self.px(x, y, c)

    def outline(self):
        src = self.img.copy()
        for y in range(self.h):
            for x in range(self.w):
                if src.getpixel((x, y))[3] != 0:
                    continue
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < self.w and 0 <= ny < self.h and src.getpixel((nx, ny))[3] > 0:
                        self.img.putpixel((x, y), OUTLINE)
                        break
        return self


def sheet(frames):
    w, h = frames[0].w, frames[0].h
    img = Image.new("RGBA", (w * len(frames), h), (0, 0, 0, 0))
    for i, f in enumerate(frames):
        img.paste(f.outline().img, (i * w, 0))
    return img


# --------------------------------------------------------------------------
# Babosa morada (caminante): 16x12, el cuadro 2 está aplastado para caminar
# --------------------------------------------------------------------------
SLIME = (150, 80, 175)
SLIME_L = (200, 140, 220)
SLIME_D = (100, 50, 125)


def slime(squash):
    c = Canvas(16, 12)
    top = 3 + squash
    c.ellipse(8, 8 + squash // 2, 6 + squash, 4 - squash // 2, SLIME)
    c.rect(2 - squash, 9, 13 + squash, 10, SLIME_D)
    c.px(5, top + 1, SLIME_L)
    c.px(6, top + 1, SLIME_L)
    c.px(5, top + 2, SLIME_L)
    # ojos mirando a la derecha
    for ex in (9, 12):
        c.rect(ex, top + 2, ex, top + 3, (255, 255, 255))
        c.px(ex, top + 3, OUTLINE)
    return c


# --------------------------------------------------------------------------
# Cuervo (pájaro): 16x12, alas arriba / alas abajo
# --------------------------------------------------------------------------
CROW = (45, 45, 70)
CROW_L = (85, 85, 120)
BEAK = (235, 170, 60)


def crow(wings_up):
    c = Canvas(16, 12)
    c.ellipse(7, 7, 5, 3, CROW)
    c.ellipse(12, 5, 2, 2, CROW)
    c.rect(14, 5, 15, 6, BEAK)
    c.px(12, 4, (230, 40, 50))
    c.rect(1, 6, 2, 7, CROW)
    if wings_up:
        for i in range(4):
            c.rect(5 + i, 1 + i, 7, 4, CROW_L)
    else:
        for i in range(3):
            c.rect(4 + i, 8, 8, 9 + i, CROW_L)
    return c


# --------------------------------------------------------------------------
# Saltarín (salta desde los huecos): 12x14, boca cerrada / boca abierta
# --------------------------------------------------------------------------
JUMP = (225, 85, 45)
JUMP_L = (250, 150, 80)
JUMP_D = (165, 50, 30)


def jumper(mouth_open):
    c = Canvas(12, 14)
    c.ellipse(6, 7, 5, 6, JUMP)
    c.rect(2, 10, 9, 12, JUMP_D)
    # púas
    for x in (2, 5, 8):
        c.px(x + 1, 0, JUMP_D)
    c.px(3, 3, JUMP_L)
    c.px(4, 2, JUMP_L)
    # ojos
    c.rect(3, 5, 4, 6, (255, 255, 255))
    c.rect(7, 5, 8, 6, (255, 255, 255))
    c.px(4, 6, OUTLINE)
    c.px(8, 6, OUTLINE)
    if mouth_open:
        c.rect(3, 8, 8, 10, (60, 15, 20))
        for x in (3, 5, 7):
            c.px(x, 8, (255, 255, 255))
    else:
        c.rect(3, 9, 8, 9, (60, 15, 20))
    return c


# --------------------------------------------------------------------------
# Planta lanzadora: 16x16, boca cerrada / boca abierta (dispara)
# --------------------------------------------------------------------------
STEM = (60, 115, 45)
LEAF = (90, 160, 60)
HEAD = (200, 50, 70)
HEAD_L = (240, 110, 120)
POT = (150, 90, 55)


def plant(mouth_open):
    c = Canvas(16, 16)
    c.rect(4, 13, 11, 15, POT)
    c.rect(3, 12, 12, 12, (120, 70, 40))
    c.rect(7, 8, 8, 12, STEM)
    c.ellipse(4, 10, 2, 1, LEAF)
    c.ellipse(11, 10, 2, 1, LEAF)
    c.ellipse(8, 4, 5, 4, HEAD)
    c.px(5, 2, HEAD_L)
    c.px(6, 1, HEAD_L)
    for x in (5, 8, 11):
        c.px(x, 5, (255, 220, 120))
    if mouth_open:
        c.rect(11, 3, 13, 6, (60, 15, 20))
    else:
        c.rect(11, 4, 13, 4, (60, 15, 20))
    c.px(9, 2, (255, 255, 255))
    c.px(9, 3, OUTLINE)
    return c


def seed():
    c = Canvas(6, 6)
    c.ellipse(2, 2, 1, 1, (120, 200, 70))
    c.rect(2, 2, 3, 3, (120, 200, 70))
    c.px(2, 2, (190, 240, 140))
    return c


def save(img, name):
    os.makedirs(DEST, exist_ok=True)
    img.resize((img.width * SCALE, img.height * SCALE), Image.NEAREST).save(os.path.join(DEST, name))


if __name__ == "__main__":
    save(sheet([slime(0), slime(1)]), "slime.png")
    save(sheet([crow(True), crow(False)]), "crow.png")
    save(sheet([jumper(False), jumper(True)]), "jumper.png")
    save(sheet([plant(False), plant(True)]), "plant.png")
    s = seed()
    save(s.outline().img, "seed.png")
    print("Enemigos generados en", os.path.normpath(DEST))
