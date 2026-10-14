"""One-off experiment: character swap with Wan 2.2 Animate on a free
Hugging Face ZeroGPU Space. Not part of the app.

Usage:
  backend/.venv/bin/python -I backend/experiments/hf_animate.py api
  backend/.venv/bin/python -I backend/experiments/hf_animate.py run VIDEO PHOTO OUT [SECONDS]

Reads HF_TOKEN from backend/.env. The token is never printed.
"""

import shutil
import sys
import time
from pathlib import Path

from gradio_client import Client, handle_file

SPACE = "alexnasa/Wan2.2-Animate-ZEROGPU"
ENV = Path(__file__).resolve().parents[1] / ".env"


def token() -> str | None:
    for line in ENV.read_text().splitlines():
        if line.startswith("HF_TOKEN="):
            return line.split("=", 1)[1].strip() or None
    return None


def main() -> None:
    client = Client(SPACE, token=token(), verbose=False)
    if sys.argv[1] == "api":
        client.view_api()
        return

    video, photo, out = sys.argv[2:5]
    seconds = float(sys.argv[5]) if len(sys.argv) > 5 else 2.0
    started = time.monotonic()
    result = client.predict(
        input_video={"video": handle_file(video)},
        max_duration_s=seconds,
        edited_frame=handle_file(photo),
        rc_str="Character Swap",
        resolution_choice="Low Res",
        api_name="/animate_scene",
    )
    elapsed = time.monotonic() - started
    print("raw result:", result)
    path = result.get("video") if isinstance(result, dict) else result
    if isinstance(path, (list, tuple)):
        path = path[0]
    if isinstance(path, dict):
        path = path.get("video") or path.get("path")
    shutil.copy(path, out)
    print(f"saved {out} in {elapsed:.0f} s")


if __name__ == "__main__":
    main()
