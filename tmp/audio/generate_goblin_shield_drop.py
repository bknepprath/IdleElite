import math
import random
import struct
import wave
from pathlib import Path


sample_rate = 44_100
duration = 0.46
random_source = random.Random(731)
modes = (
    (238.0, 0.42, 11.0, 0.0),
    (377.0, 0.30, 14.0, 0.8),
    (611.0, 0.22, 18.0, 1.7),
    (947.0, 0.14, 23.0, 2.4),
    (1483.0, 0.08, 31.0, 0.4),
)
samples = []
for index in range(round(sample_rate * duration)):
    time = index / sample_rate
    onset = 1.0 - math.exp(-time * 900.0)
    ring = sum(
        amplitude * math.sin(math.tau * frequency * time + phase) * math.exp(-decay * time)
        for frequency, amplitude, decay, phase in modes
    )
    wood = 0.20 * math.sin(math.tau * 118.0 * time) * math.exp(-24.0 * time)
    transient = (random_source.random() * 2.0 - 1.0) * 0.24 * math.exp(-70.0 * time)
    fade = min(1.0, max(0.0, (duration - time) / 0.035))
    samples.append((ring + wood + transient) * onset * fade)

peak = max(abs(sample) for sample in samples)
pcm = b"".join(struct.pack("<h", round(sample / peak * 25_500.0)) for sample in samples)
output = Path(r"assets/sfx/fight_goblin_shield_drop.wav")
output.parent.mkdir(parents=True, exist_ok=True)
with wave.open(str(output), "wb") as target:
    target.setnchannels(1)
    target.setsampwidth(2)
    target.setframerate(sample_rate)
    target.writeframes(pcm)

print(f"wrote {output} samples={len(samples)} peak=0.778")
