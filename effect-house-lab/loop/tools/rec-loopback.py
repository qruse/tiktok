"""Record what the PC speakers play (WASAPI loopback) into a WAV file.

Effect House's own preview recorder drops audio, so record-run.ps1 runs this alongside it
and mux-audio.ps1 lines the two up afterwards.
Usage: python rec-loopback.py OUT.wav SECONDS
Needs: pip install --user PyAudioWPatch
"""
import sys
import threading
import time
import wave

import pyaudiowpatch as pa

out_path, seconds = sys.argv[1], float(sys.argv[2])
p = pa.PyAudio()
wasapi = p.get_host_api_info_by_type(pa.paWASAPI)
spk = p.get_device_info_by_index(wasapi["defaultOutputDevice"])
loop = next(d for d in p.get_loopback_device_info_generator() if spk["name"] in d["name"])
rate, ch = int(loop["defaultSampleRate"]), loop["maxInputChannels"]

# WASAPI loopback delivers no frames while nothing is playing, which would shift the timeline.
# Playing digital silence on the same speaker keeps the stream running at a constant rate.
stop = threading.Event()
def keep_alive():
    o = p.open(format=pa.paInt16, channels=ch, rate=rate, output=True, output_device_index=spk["index"])
    zeros = b"\x00" * (1024 * ch * 2)
    while not stop.is_set():
        o.write(zeros)
    o.close()
t = threading.Thread(target=keep_alive, daemon=True)
t.start()
time.sleep(0.3)

w = wave.open(out_path, "wb")
w.setnchannels(ch); w.setsampwidth(2); w.setframerate(rate)
s = p.open(format=pa.paInt16, channels=ch, rate=rate, input=True, input_device_index=loop["index"], frames_per_buffer=1024)
print("start", time.time(), flush=True)
need = int(rate * seconds)
got = 0
while got < need:
    data = s.read(1024, exception_on_overflow=False)
    w.writeframes(data)
    got += 1024
s.close(); w.close()
stop.set(); t.join(2)
p.terminate()
print("done", out_path, flush=True)
