"""One-off experiment: Wan 2.2 Animate character replacement on a free
Hugging Face ZeroGPU Space (Iceyy4400/wan22-animate-character-replace).

Usage:
  backend/.venv/bin/python -I backend/experiments/hf_replace.py VIDEO PHOTO OUT \
      [--size 832x480] [--frames 49] [--prompt "..."]

Reads HF_TOKEN from backend/.env. The token is never printed.
"""

import argparse
import shutil
import time
from pathlib import Path

from gradio_client import Client, handle_file

ENV = Path(__file__).resolve().parents[1] / ".env"


def token() -> str | None:
    for line in ENV.read_text().splitlines():
        if line.startswith("HF_TOKEN="):
            return line.split("=", 1)[1].strip() or None
    return None

SPACE = "Iceyy4400/wan22-animate-character-replace"


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("video")
    ap.add_argument("photo")
    ap.add_argument("out")
    ap.add_argument("--size", default="832x480")
    ap.add_argument("--frames", type=int, default=49)
    ap.add_argument("--prompt", default="the person is dancing at a party")
    a = ap.parse_args()
    w, h = (int(x) for x in a.size.split("x"))

    client = Client(SPACE, token=token(), verbose=False)
    t0 = time.monotonic()
    job = client.submit(
        reference_image=handle_file(a.photo),
        gen_width=w,
        gen_height=h,
        video={"video": handle_file(a.video)},
        video_width=w,
        video_height=h,
        frame_load_cap=a.frames,
        positive_prompt=a.prompt,
        api_name="/generate_video",
    )
    last = None
    while not job.done():
        s = job.status()
        key = (s.code, s.rank)
        if key != last:
            print(f"{time.monotonic() - t0:6.1f}s {s.code} rank={s.rank} eta={s.eta}")
            last = key
        time.sleep(2)
    result = job.result()
    print(f"{time.monotonic() - t0:6.1f}s done: {result}")
    path = result[0] if isinstance(result, (list, tuple)) else result
    if isinstance(path, dict):
        path = path.get("video") or path.get("path")
    shutil.copy(path, a.out)
    print("saved", a.out)


if __name__ == "__main__":
    main()
