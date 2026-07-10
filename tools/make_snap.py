"""Generate a short, punchy 'snap' sound effect as a WAV file.

The snap is a quick noise transient followed by a fast-decaying pitched
'pop' (a sine that drops in pitch), which reads as a satisfying click/snap
when a puzzle piece locks into place.
"""
import math
import random
import struct
import wave

SAMPLE_RATE = 44100
DURATION = 0.14  # seconds


def main() -> None:
    n = int(SAMPLE_RATE * DURATION)
    frames = bytearray()
    random.seed(7)
    for i in range(n):
        t = i / SAMPLE_RATE
        # Fast exponential envelope.
        env = math.exp(-t * 38.0)
        # Pitched 'pop': sine sweeping down from ~1400Hz to ~500Hz.
        freq = 1400.0 - 900.0 * (t / DURATION)
        tone = math.sin(2 * math.pi * freq * t)
        # Sharp noise transient in the first few ms for the 'click'.
        click_env = math.exp(-t * 320.0)
        noise = (random.random() * 2 - 1) * click_env
        sample = env * (0.7 * tone) + 0.6 * noise
        # Gentle soft-clip and scale to 16-bit.
        sample = max(-1.0, min(1.0, sample))
        frames += struct.pack('<h', int(sample * 32767 * 0.9))

    with wave.open('assets/audio/snap.wav', 'wb') as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SAMPLE_RATE)
        w.writeframes(bytes(frames))
    print('wrote assets/audio/snap.wav', n, 'frames')


if __name__ == '__main__':
    main()
