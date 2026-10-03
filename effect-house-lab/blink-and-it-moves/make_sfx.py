# Synthesizes the four original sound effects (v2). No samples, no third-party audio.
# v2 (2026-10-03 tick 2): v1 put 99% of the energy below 150 Hz (thump 40 Hz, heart 55 Hz, drone 55 Hz),
# which phone speakers cannot reproduce. v2 keeps the low body and adds harmonics and transients in 150-2000 Hz.
#   python make_sfx.py <out_dir>   -> drone/thump/heart/sting .wav + .mp3 and a level report
import sys, os, wave
import numpy as np
import lameenc

SR = 44100
rng = np.random.default_rng(7)


def band(x, lo, hi):
    """Brick-wall band-pass by FFT (fine for one-shot synthesis)."""
    X = np.fft.rfft(x); f = np.fft.rfftfreq(len(x), 1 / SR)
    X[(f < lo) | (f > hi)] = 0
    return np.fft.irfft(X, len(x))


def periodic_noise(n, lo, hi):
    """Band-limited noise that loops seamlessly (random phase on exact FFT bins)."""
    f = np.fft.rfftfreq(n, 1 / SR)
    X = np.where((f >= lo) & (f <= hi), np.exp(2j * np.pi * rng.random(len(f))), 0)
    y = np.fft.irfft(X, n)
    return y / np.abs(y).max()


def t_(dur):
    return np.arange(int(SR * dur)) / SR


def fade(x, a=0.003, r=0.02):
    na, nr = int(SR * a), int(SR * r)
    x = x.copy(); x[:na] *= np.linspace(0, 1, na); x[-nr:] *= np.linspace(1, 0, nr)
    return x


def norm(x, peak_db):
    return x / np.abs(x).max() * 10 ** (peak_db / 20)


def thump(dur=0.9):
    t = t_(dur)
    f = 55 + 125 * np.exp(-t / 0.05)                   # pitch drop 180 -> 55 Hz
    body = np.tanh(5 * np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t / 0.2))  # hard drive -> 165-800 Hz harmonics
    boom = np.sin(2 * np.pi * 190 * t) * np.exp(-t / 0.09)
    knock = band(rng.standard_normal(len(t)), 220, 1600) * np.exp(-t / 0.035)
    room = band(rng.standard_normal(len(t)), 200, 700) * np.exp(-t / 0.25)
    x = 0.7 * body + 0.5 * boom + 0.8 * knock / np.abs(knock).max() + 0.1 * room / np.abs(room).max()
    return norm(fade(x), -1.5)


def beat(t, t0, amp):
    u = np.clip(t - t0, 0, None); on = t >= t0
    f = 65 + 50 * np.exp(-u / 0.03)
    ph = np.cumsum(np.where(on, f, 0)) / SR
    b = np.tanh(5 * np.sin(2 * np.pi * ph) * np.exp(-u / 0.07)) * on
    mid = np.sin(2 * np.pi * 2.5 * ph) * np.exp(-u / 0.05) * on        # ~160-290 Hz partial a phone can play
    tick = band(rng.standard_normal(len(t)), 200, 1000) * np.exp(-u / 0.02) * on
    return amp * (0.5 * b + 1.0 * mid + 0.9 * tick / np.abs(tick).max())


def heart(dur=0.9):
    t = t_(dur)
    return norm(fade(beat(t, 0.0, 1.0) + beat(t, 0.19, 0.7)), -2.0)


def drone(dur=8.0):
    n = int(SR * dur); t = np.arange(n) / SR
    # all partials are multiples of 1/8 Hz, so the 8 s file loops without a seam
    low = np.sin(2 * np.pi * 55 * t) + 0.5 * np.sin(2 * np.pi * 82.5 * t)
    mid = (0.5 * np.sin(2 * np.pi * 110.125 * t) + 0.5 * np.sin(2 * np.pi * 164.875 * t)
           + 0.6 * np.sin(2 * np.pi * 220.25 * t) + 0.45 * np.sin(2 * np.pi * 233.0 * t)   # minor-second rub
           + 0.35 * np.sin(2 * np.pi * 329.875 * t) + 0.25 * np.sin(2 * np.pi * 349.0 * t))
    swell = 0.75 + 0.25 * np.sin(2 * np.pi * 0.25 * t)
    air = periodic_noise(n, 300, 1400) * (0.6 + 0.4 * np.sin(2 * np.pi * 0.125 * t + 1.0))
    x = np.tanh(0.6 * (0.7 * low + mid) * swell) + 0.3 * air
    return norm(x, -4.0)                                # no fade: must loop


def sting(dur=1.4):
    t = t_(dur)
    hit = np.tanh(3 * np.sin(2 * np.pi * np.cumsum(40 + 120 * np.exp(-t / 0.05)) / SR) * np.exp(-t / 0.35))
    cluster = sum(np.sin(2 * np.pi * f * t + rng.random() * 6) for f in (311, 330, 466, 494, 740)) / 5
    cluster *= np.exp(-t / 0.45) * np.minimum(1, t / 0.01)
    screech = band(rng.standard_normal(len(t)), 1200, 5000) * np.exp(-t / 0.25)
    x = 0.6 * hit + 1.2 * cluster + 0.45 * screech / np.abs(screech).max()
    return norm(fade(x, 0.002, 0.08), -1.5)


def save(x, path):
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    with wave.open(path + '.wav', 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(SR); w.writeframes(pcm.tobytes())
    enc = lameenc.Encoder(); enc.set_bit_rate(128); enc.set_in_sample_rate(SR); enc.set_channels(1); enc.set_quality(2)
    with open(path + '.mp3', 'wb') as f:
        f.write(enc.encode(pcm.tobytes()) + enc.flush())


def report(name, x):
    hp = band(x, 250, 20000)                           # what a phone speaker roughly reproduces
    db = lambda v: 20 * np.log10(max(1e-9, v))
    print(f"{name:6s} peak={db(np.abs(x).max()):6.1f} rms={db(np.sqrt((x**2).mean())):6.1f} "
          f"phone_rms(>250Hz)={db(np.sqrt((hp**2).mean())):6.1f} share>250Hz={100*(hp**2).sum()/(x**2).sum():5.1f}%")


if __name__ == '__main__':
    out = sys.argv[1] if len(sys.argv) > 1 else '.'
    os.makedirs(out, exist_ok=True)
    for name, fn in (('drone', drone), ('thump', thump), ('heart', heart), ('sting', sting)):
        x = fn(); save(x, os.path.join(out, name)); report(name, x)
