#!/usr/bin/env python3
"""Generates the orb textures used for combo points and runes.

Writes 32-bit uncompressed TGA files, which the 3.3.5a client loads from
addon folders. The orb fill is drawn white so the addon can tint it per
resource with SetVertexColor.

Usage: python3 tools/make_orb_textures.py
"""

import math
import os

SIZE = 64
SAMPLES = 4  # supersampling per axis
MEDIA = os.path.join(os.path.dirname(__file__), "..", "PersonalResourceBar", "Media")


def write_tga(path, pixels):
    """pixels: row-major top-down list of (r, g, b, a) floats in 0..1."""
    header = bytes([
        0, 0, 2, 0, 0, 0, 0, 0,
        0, 0, 0, 0,
        SIZE & 0xFF, SIZE >> 8,
        SIZE & 0xFF, SIZE >> 8,
        32,
        0x28,  # 8 alpha bits, top-left origin
    ])
    body = bytearray()
    for r, g, b, a in pixels:
        body += bytes((
            max(0, min(255, int(b * 255 + 0.5))),
            max(0, min(255, int(g * 255 + 0.5))),
            max(0, min(255, int(r * 255 + 0.5))),
            max(0, min(255, int(a * 255 + 0.5))),
        ))
    with open(path, "wb") as f:
        f.write(header)
        f.write(body)


def supersample(shade):
    """shade(nx, ny) -> (r, g, b, a) for a point in -1..1 space."""
    pixels = []
    step = 1.0 / SAMPLES
    for y in range(SIZE):
        for x in range(SIZE):
            acc_r = acc_g = acc_b = acc_a = 0.0
            for sy in range(SAMPLES):
                for sx in range(SAMPLES):
                    px = (x + (sx + 0.5) * step) / SIZE * 2 - 1
                    py = (y + (sy + 0.5) * step) / SIZE * 2 - 1
                    r, g, b, a = shade(px, py)
                    # Accumulate premultiplied so edges don't pick up halos.
                    acc_r += r * a
                    acc_g += g * a
                    acc_b += b * a
                    acc_a += a
            n = SAMPLES * SAMPLES
            a = acc_a / n
            if a > 0.0001:
                pixels.append((acc_r / n / a, acc_g / n / a, acc_b / n / a, a))
            else:
                pixels.append((0.0, 0.0, 0.0, 0.0))
    return pixels


def orb_fill(nx, ny):
    """A shaded sphere plus a soft halo, white so it can be tinted."""
    d = math.hypot(nx, ny)
    radius = 0.62

    if d <= radius:
        t = d / radius
        value = 1.0 - 0.40 * (t ** 2)

        # Darker rim so the orb reads as round against the socket.
        if t > 0.78:
            value *= 1.0 - 0.45 * ((t - 0.78) / 0.22)

        # Soft gloss highlight up and to the left.
        hd = math.hypot(nx + 0.34 * radius, ny + 0.38 * radius) / (0.62 * radius)
        if hd < 1.0:
            value += 0.55 * (1.0 - hd) ** 2

        return min(1.0, value), min(1.0, value), min(1.0, value), 1.0

    if d >= 1.0:
        return 0.0, 0.0, 0.0, 0.0

    # Glow bleeding out over the socket rim.
    falloff = (d - radius) / (1.0 - radius)
    return 1.0, 1.0, 1.0, 0.62 * (1.0 - falloff) ** 2.2


def orb_socket(nx, ny):
    """A dark ring the orb sits in, visible whether or not the orb is lit."""
    d = math.hypot(nx, ny)
    outer, inner = 0.99, 0.68

    if d > outer:
        return 0.0, 0.0, 0.0, 0.0

    if d >= inner:
        # Bevel: catches light on the top edge, darker along the bottom.
        upness = max(-1.0, min(1.0, -ny / outer))
        value = 0.30 + 0.22 * upness
        # Thin dark outline around the outside so it reads on any backdrop.
        if d > outer - 0.09:
            value *= 0.35
        return value, value, value, 0.97

    return 0.04, 0.04, 0.04, 0.85


def main():
    os.makedirs(MEDIA, exist_ok=True)
    for name, shade in (("orb-fill", orb_fill), ("orb-socket", orb_socket)):
        path = os.path.join(MEDIA, name + ".tga")
        write_tga(path, supersample(shade))
        print("wrote %s (%d bytes)" % (path, os.path.getsize(path)))


if __name__ == "__main__":
    main()
