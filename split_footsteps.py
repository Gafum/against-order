"""
Split a WAV file containing multiple footsteps into individual WAV samples.
Uses silence detection to find boundaries between steps.
"""
import wave
import struct
import os

INPUT  = r"e:\Projects\Games\Godot\Against Order\against-order\assets\Musik\Event\Motion\footstep\footstep.wav"
OUTDIR = r"e:\Projects\Games\Godot\Against Order\against-order\assets\Musik\Event\Motion\footstep"

# Tuning parameters
SILENCE_THRESHOLD = 0.03   # amplitude below which we consider silence (0–1 range)
MIN_SILENCE_MS    = 60     # a gap must be at least this long to count as a separator
MIN_STEP_MS       = 60     # ignore chunks shorter than this (noise artefacts)
MAX_STEP_MS       = 600    # ignore chunks longer than this (the full recording)
PRE_PAD_MS        = 10     # keep a tiny bit of silence before each step
POST_PAD_MS       = 30     # keep silence after each step (natural tail)

def read_wav(path):
    with wave.open(path, 'rb') as w:
        n_ch    = w.getnchannels()
        sampw   = w.getsampwidth()
        rate    = w.getframerate()
        frames  = w.readframes(w.getnframes())
    n_samples = len(frames) // sampw

    if sampw == 1:
        raw = struct.unpack(f'<{n_samples}B', frames)
        samples = [(s - 128) / 128.0 for s in raw]
    elif sampw == 2:
        raw = struct.unpack(f'<{n_samples}h', frames)
        samples = [s / 32768.0 for s in raw]
    elif sampw == 3:
        # 24-bit: unpack 3 bytes at a time as signed int
        samples = []
        for i in range(0, len(frames), 3):
            b0, b1, b2 = frames[i], frames[i+1], frames[i+2]
            val = (b2 << 16) | (b1 << 8) | b0
            if val >= 0x800000:
                val -= 0x1000000
            samples.append(val / 8388608.0)
    elif sampw == 4:
        raw = struct.unpack(f'<{n_samples}i', frames)
        samples = [s / 2147483648.0 for s in raw]
    else:
        raise ValueError(f"Unsupported sample width: {sampw}")

    # mix to mono for analysis
    if n_ch > 1:
        mono = [sum(samples[i:i+n_ch])/n_ch for i in range(0, len(samples), n_ch)]
    else:
        mono = samples
    return mono, samples, n_ch, sampw, rate

def write_wav(path, samples, n_ch, sampw, rate):
    if sampw == 1:
        packed = struct.pack(f'<{len(samples)}B',
                             *[max(0, min(255, int(s * 128 + 128))) for s in samples])
    elif sampw == 2:
        packed = struct.pack(f'<{len(samples)}h',
                             *[max(-32768, min(32767, int(s * 32768))) for s in samples])
    elif sampw == 3:
        buf = bytearray()
        for s in samples:
            val = max(-8388608, min(8388607, int(s * 8388608)))
            if val < 0:
                val += 0x1000000
            buf += bytes([val & 0xFF, (val >> 8) & 0xFF, (val >> 16) & 0xFF])
        packed = bytes(buf)
    elif sampw == 4:
        packed = struct.pack(f'<{len(samples)}i',
                             *[max(-(1<<31), min((1<<31)-1, int(s * (1<<31)))) for s in samples])
    else:
        raise ValueError(f"Unsupported sample width: {sampw}")

    with wave.open(path, 'wb') as w:
        w.setnchannels(n_ch)
        w.setsampwidth(sampw)
        w.setframerate(rate)
        w.writeframes(packed)

def split(mono, rate):
    """Return list of (start, end) frame indices for each footstep in the mono signal."""
    min_sil  = int(rate * MIN_SILENCE_MS  / 1000)
    min_step = int(rate * MIN_STEP_MS     / 1000)
    max_step = int(rate * MAX_STEP_MS     / 1000)
    pre_pad  = int(rate * PRE_PAD_MS      / 1000)
    post_pad = int(rate * POST_PAD_MS     / 1000)

    # Build a boolean "is loud" array
    loud = [abs(s) > SILENCE_THRESHOLD for s in mono]

    regions = []
    in_region = False
    start = 0
    sil_count = 0

    for i, l in enumerate(loud):
        if not in_region:
            if l:
                in_region = True
                start = i
                sil_count = 0
        else:
            if not l:
                sil_count += 1
                if sil_count >= min_sil:
                    end = i - sil_count
                    length = end - start
                    if min_step < length < max_step:
                        regions.append((max(0, start - pre_pad),
                                        min(len(mono)-1, end + post_pad)))
                    in_region = False
            else:
                sil_count = 0

    # Catch last region
    if in_region:
        end = len(mono)
        length = end - start
        if min_step < length < max_step:
            regions.append((max(0, start - pre_pad), end))

    return regions

def main():
    print(f"Reading {INPUT} ...")
    mono, raw_samples, n_ch, sampw, rate = read_wav(INPUT)
    print(f"  Channels={n_ch}, SampleWidth={sampw}, Rate={rate}, Samples={len(mono)}")

    regions = split(mono, rate)
    print(f"  Found {len(regions)} footstep(s)")

    for idx, (s, e) in enumerate(regions):
        # Extract the raw multi-channel slice
        chunk = raw_samples[s * n_ch : e * n_ch]
        dur_ms = (e - s) * 1000 // rate
        name = f"step_{idx+1:02d}.wav"
        out_path = os.path.join(OUTDIR, name)
        write_wav(out_path, chunk, n_ch, sampw, rate)
        print(f"  → {name}  ({dur_ms} ms)")

    print("Done.")

if __name__ == "__main__":
    main()
