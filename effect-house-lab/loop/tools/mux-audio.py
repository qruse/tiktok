"""Put loopback audio (rec-loopback.py) onto a silent Effect House preview recording, in sync.

The app recorder starts a few seconds after the click and its timeline runs ~1% slow, so the
offset and speed are fitted, not assumed: every sudden brightness change in the video
(blink blackout, flash, scene cut) is matched to a sudden rise in the audio, and the
(scale, offset) that lines up the most events wins.
Usage: python mux-audio.py VIDEO.mp4 AUDIO.wav OUT.mp4 [--width 540]
Prints the fit and the per-event error. Check that "matched" covers most events and the error is under ~0.15 s.
"""
import argparse
import glob
import os
import subprocess
import wave

import numpy as np

ap = argparse.ArgumentParser()
ap.add_argument("video"); ap.add_argument("audio"); ap.add_argument("out")
ap.add_argument("--width", type=int, default=540)
a = ap.parse_args()
ff = glob.glob(os.path.expandvars(r"%LOCALAPPDATA%\Packages\PythonSoftwareFoundation.Python.3.11_qbz5n2kfra8p0"
                                  r"\LocalCache\local-packages\Python311\site-packages\imageio_ffmpeg\binaries\ffmpeg*.exe"))[0]

# video events: frame-to-frame brightness jumps
raw = subprocess.run([ff, "-v", "error", "-i", a.video, "-vf", "scale=36:64,format=gray", "-f", "rawvideo", "-"],
                     capture_output=True).stdout
fps = 30.0
f = np.frombuffer(raw, np.uint8).reshape(-1, 64 * 36).mean(1)
vdur = len(f) / fps
vev = [i / fps for i in range(1, len(f)) if abs(f[i] - f[i - 1]) > 25]
# collapse events closer than 0.1 s
ve = []
for t in vev:
    if not ve or t - ve[-1] > 0.1:
        ve.append(t)

# audio events: rises in 10 ms peak envelope
w = wave.open(a.audio); sr = w.getframerate(); ch = w.getnchannels()
x = np.frombuffer(w.readframes(w.getnframes()), np.int16).reshape(-1, ch).astype(float).mean(1) / 32768
hop = sr // 100
env = np.array([np.abs(x[i:i + hop]).max() for i in range(0, len(x) - hop, hop)])
adur = len(x) / sr
if env.max() < 0.01:
    raise SystemExit("audio is silent: check the speaker/output device and that the preview is not muted")
rise = np.zeros_like(env)
rise[1:] = np.clip(np.diff(env), 0, None)

def score(s, o):
    tot = 0.0
    for t in ve:
        c = int((s * t + o) * 100)
        if 15 <= c < len(rise) - 15:
            tot += rise[c - 15:c + 15].max()
    return tot

best = (-1, 1.0, 0.0)
for s in np.arange(0.98, 1.03, 0.0025):
    for o in np.arange(0.0, max(0.5, adur - vdur * 0.5), 0.02):
        sc = score(s, o)
        if sc > best[0]:
            best = (sc, s, o)
_, s, o = best
errs = []
for t in ve:
    c = int((s * t + o) * 100)
    if 15 <= c < len(rise) - 15:
        k = int(np.argmax(rise[c - 15:c + 15])) - 15
        if rise[c + k] > 0.02:
            errs.append(k / 100)
print("fit: audio = %.4f * video + %.3f s; video events %d, matched %d, mean |err| %.3f s"
      % (s, o, len(ve), len(errs), float(np.mean(np.abs(errs))) if errs else -1))

subprocess.run([ff, "-hide_banner", "-loglevel", "error", "-y", "-i", a.video, "-ss", "%.3f" % o, "-i", a.audio,
                "-filter:a", "atempo=%.4f" % s, "-map", "0:v", "-map", "1:a", "-vf", "scale=%d:-2" % a.width,
                "-c:v", "libx264", "-preset", "slow", "-crf", "27", "-pix_fmt", "yuv420p", "-c:a", "aac", "-b:a", "128k",
                "-shortest", "-movflags", "+faststart", a.out], check=True)
print("saved", a.out, "%.2f MB" % (os.path.getsize(a.out) / 1e6))
