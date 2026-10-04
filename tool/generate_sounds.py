"""Synthesizes the wheel's sounds: the tick of a peg and the stop chime.

Run from the repository root, with no extra package:
    python3 tool/generate_sounds.py
"""

import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "assets" / "sounds"
RATE = 44100


def write(name, samples):
    peak = max(abs(s) for s in samples)
    OUT.mkdir(parents=True, exist_ok=True)
    with wave.open(str(OUT / name), "wb") as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(
            b"".join(struct.pack("<h", round(s / peak * 0.9 * 32767)) for s in samples)
        )


def tick():
    """A short plastic click, like the pointer flapping off a peg."""
    rng = random.Random(7)
    n = int(RATE * 0.045)
    out = []
    previous = 0.0
    for i in range(n):
        t = i / RATE
        # A tiny burst of high-passed noise for the attack...
        noise = rng.uniform(-1, 1)
        high = noise - previous
        previous = noise
        burst = high * math.exp(-t / 0.0015)
        # ...over two quickly damped resonances for the body.
        body = (
            math.sin(2 * math.pi * 1900 * t) * math.exp(-t / 0.006)
            + 0.6 * math.sin(2 * math.pi * 3400 * t) * math.exp(-t / 0.003)
            + 0.5 * math.sin(2 * math.pi * 820 * t) * math.exp(-t / 0.008)
        )
        out.append(0.7 * burst + body)
    return out


def bell(t, frequency):
    """A small bell: a few inharmonic partials, the higher ones dying faster."""
    if t < 0:
        return 0.0
    attack = min(1.0, t / 0.003)
    partials = [(1.0, 1.0, 0.45), (2.0, 0.35, 0.25), (2.76, 0.25, 0.12), (5.4, 0.12, 0.05)]
    return attack * sum(
        a * math.sin(2 * math.pi * frequency * r * t) * math.exp(-t / d)
        for r, a, d in partials
    )


def chime():
    """A cheerful rising arpeggio, played when the wheel stops."""
    notes = [(0.0, 1046.5), (0.08, 1318.5), (0.16, 1568.0), (0.24, 2093.0)]
    n = int(RATE * 1.1)
    out = []
    for i in range(n):
        t = i / RATE
        s = sum(bell(t - start, f) for start, f in notes)
        # Fade out the tail so the sound ends on silence.
        fade = min(1.0, (n - i) / (RATE * 0.15))
        out.append(s * fade)
    return out


if __name__ == "__main__":
    write("tick.wav", tick())
    write("stop.wav", chime())
