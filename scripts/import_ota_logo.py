"""Import the updated ChoreRobotics logo from the OTA server and emit app variants.

Source: ../ota/server/static/logo.png — a two-tone lockup (orange bracket + black
chevrons forming the hex mark, followed by a black "CHORE" wordmark).

The app renders on a near-black surface (AppColors.bgPrimary), so the black ink has
to be re-inked light for every on-device variant; the untouched original is kept as
the light-background lockup for print/web use.
"""
from PIL import Image
import numpy as np
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "assets" / "logo"

# Walk up rather than hardcoding ../../ota — the repo is often checked out as a
# git worktree several levels deeper than the normal sibling layout.
SRC_REL = Path("ota") / "server" / "static" / "logo.png"


def find_source() -> Path:
    for base in [ROOT, *ROOT.parents]:
        candidate = base / SRC_REL
        if candidate.exists():
            return candidate
    raise SystemExit(f"could not find {SRC_REL} in any ancestor of {ROOT}")

# Matches AppColors.textPrimary so the wordmark sits at the same optical weight as
# the surrounding UI text instead of glaring pure white.
INK_LIGHT = (232, 234, 237)

# The only two inks in the source artwork.
ORANGE = (255, 132, 0)
BLACK = (0, 0, 0)

# Full lockup is drawn up to 260 logical px wide; 2x gives headroom on 3x screens.
UPSCALE = 2


def load_source(path: Path) -> Image.Image:
    return Image.open(path).convert("RGBA")


def relight(img: Image.Image, ink=INK_LIGHT) -> Image.Image:
    """Re-ink the black shapes to `ink`, leaving orange as-is.

    Every pixel is `t` parts orange over `1 - t` parts black (alpha is straight, so
    transparency is a separate axis). Because black contributes nothing to red and
    orange saturates it, `t = r / 255` recovers that fraction exactly — so the same
    lerp handles flat fills and the anti-aliased pixels along the seam where the
    orange bracket meets the chevrons. Classifying pixels into two buckets instead
    would leave those seam pixels a muddy dark orange against the new light ink.
    """
    arr = np.array(img).astype(np.float32)
    t = (arr[..., 0:1] / ORANGE[0]).clip(0.0, 1.0)

    recolored = t * np.array(ORANGE, np.float32) + (1.0 - t) * np.array(ink, np.float32)
    arr[..., :3] = recolored.round().clip(0, 255)

    return Image.fromarray(arr.astype(np.uint8), "RGBA")


def trim(img: Image.Image) -> Image.Image:
    bbox = img.getbbox()
    return img.crop(bbox) if bbox else img


def scale(img: Image.Image, factor: int) -> Image.Image:
    if factor == 1:
        return img
    return img.resize((img.width * factor, img.height * factor), Image.LANCZOS)


def mark_boundary(img: Image.Image) -> int:
    """Return the x column where the hex mark ends and the wordmark begins.

    The mark is kerned as tightly to the "H" as the letters are to each other, so a
    gap-width threshold can't find the seam. Instead, split the lockup into runs of
    inked columns — the mark doubles as the "C", so it is simply the first run.
    """
    col_has_ink = (np.array(img)[..., 3] > 16).any(axis=0)
    xs = np.where(col_has_ink)[0]
    if len(xs) == 0:
        raise SystemExit("source logo appears blank")

    for x in range(int(xs[0]), img.width):
        if not col_has_ink[x]:
            return x
    raise SystemExit("no gap found after the hex mark")


def save(img: Image.Image, name: str):
    path = OUT / name
    img.save(path, "PNG", optimize=True)
    print(f"  wrote assets/logo/{name}  ({img.width}x{img.height})")


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    src_path = find_source()
    src = trim(load_source(src_path))
    print(f"source {src_path} ({src.width}x{src.height})")

    dark = relight(src)  # re-inked — every in-app surface is near-black

    save(scale(src, UPSCALE), "chore-robotics-full-light.png")  # original black ink
    save(scale(dark, UPSCALE), "chore-robotics-full-dark.png")

    # Split before upscaling so the boundary is measured in source pixels.
    seam = mark_boundary(dark)
    save(scale(trim(dark.crop((0, 0, seam, dark.height))), UPSCALE), "chore-robotics-mark.png")
    save(scale(trim(dark.crop((seam, 0, dark.width, dark.height))), UPSCALE), "chore-robotics-wordmark.png")

    print("done.")


if __name__ == "__main__":
    main()
