"""Generate a soft pad + pluck arpeggio bed with numpy. usage: python3 audio.py OUT.wav [seconds]"""
import sys, wave, numpy as np
sr = 44100
dur = float(sys.argv[2]) if len(sys.argv) > 2 else 30.0
n = int(sr * dur)
t = np.arange(n) / sr
L = np.zeros(n); R = np.zeros(n)
f = lambda m: 440 * 2 ** ((m - 69) / 12)
chords = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]  # Am F C G
beat = 0.6; bar = beat * 4
def add(sig, start, pan=0.5):
    i = int(start * sr); j = min(n, i + len(sig))
    if i >= n: return
    L[i:j] += sig[:j - i] * (1 - pan); R[i:j] += sig[:j - i] * pan
ci = 0; pos = 0.0
while pos < dur:
    ch = chords[ci % 4]; seg = bar * 2
    m = int(sr * (seg + 1.0)); tt = np.arange(m) / sr
    env = np.minimum(tt / 1.2, 1) * np.clip((seg + 1.0 - tt) / 1.0, 0, 1)
    for k, note in enumerate(ch):
        for det in (-0.003, 0.003):
            fr = f(note - 12) * (1 + det)
            add(0.05 * env * (np.sin(2 * np.pi * fr * tt) + 0.3 * np.sin(2 * np.pi * 2 * fr * tt)), pos, 0.3 + 0.2 * k)
    # pluck arpeggio, eighths
    steps = int(seg / (beat / 2)); order = [0, 1, 2, 1, 2, 1, 0, 2]
    for s in range(steps):
        note = ch[order[s % 8]] + 12
        pm = int(sr * 0.9); pt = np.arange(pm) / sr
        p = np.exp(-pt * 5.5) * (np.sin(2 * np.pi * f(note) * pt) + 0.25 * np.sin(2 * np.pi * 2 * f(note) * pt))
        p[:200] *= np.linspace(0, 1, 200)
        add(0.06 * p, pos + s * beat / 2, 0.25 + 0.5 * ((s % 4) / 3))
    pos += seg; ci += 1
sig = np.stack([L, R], 1)
fade = np.minimum(t / 1.5, 1) * np.clip((dur - t) / 2.0, 0, 1)
sig *= fade[:, None]
sig = sig / np.abs(sig).max() * 0.35
with wave.open(sys.argv[1], 'wb') as w:
    w.setnchannels(2); w.setsampwidth(2); w.setframerate(sr)
    w.writeframes((sig * 32767).astype('<i2').tobytes())
