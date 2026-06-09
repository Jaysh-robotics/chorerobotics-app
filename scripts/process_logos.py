"""Strip flat backgrounds from the /assets/new/ logo files and emit transparent PNGs."""
from PIL import Image
import numpy as np
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "assets" / "new"
OUT = ROOT / "assets" / "logo"
OUT.mkdir(parents=True, exist_ok=True)


def remove_bg(src_path: Path, out_path: Path, *, bg: str, tolerance: int = 24, crop: bool = True):
    img = Image.open(src_path).convert("RGBA")
    arr = np.array(img)
    r, g, b, _a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]

    if bg == "black":
        mask = (r < tolerance) & (g < tolerance) & (b < tolerance)
    elif bg == "white":
        mask = (r > 255 - tolerance) & (g > 255 - tolerance) & (b > 255 - tolerance)
    elif bg == "grey":
        # near-uniform light grey ~ F4F4F4 - F8F8F8
        mask = (
            (r > 235) & (g > 235) & (b > 235)
            & (np.abs(r.astype(int) - g.astype(int)) < 8)
            & (np.abs(g.astype(int) - b.astype(int)) < 8)
        )
    else:
        raise ValueError(bg)

    arr[..., 3] = np.where(mask, 0, 255)

    # smooth alpha at fringes: any pixel that's close to bg also gets a soft alpha
    if bg == "black":
        intensity = arr[..., :3].max(axis=2)
        soft = (intensity < 64) & ~mask
        arr[..., 3] = np.where(soft, (intensity * 4).clip(0, 255).astype(np.uint8), arr[..., 3])
    elif bg in ("white", "grey"):
        intensity = arr[..., :3].min(axis=2)
        soft = (intensity > 192) & ~mask
        arr[..., 3] = np.where(soft, ((255 - intensity) * 4).clip(0, 255).astype(np.uint8), arr[..., 3])

    out = Image.fromarray(arr, "RGBA")
    if crop:
        bbox = out.getbbox()
        if bbox:
            out = out.crop(bbox)
    out.save(out_path, "PNG", optimize=True)
    print(f"  wrote {out_path.relative_to(ROOT)}  ({out.size[0]}x{out.size[1]})")


def main():
    print("processing new logos...")
    remove_bg(
        SRC / "WhatsApp Image 2026-05-21 at 19.07.54 (1).jpeg",
        OUT / "chore-robotics-full-dark.png",
        bg="black",
        tolerance=48,
    )
    remove_bg(
        SRC / "WhatsApp Image 2026-05-21 at 19.22.37 (1).jpeg",
        OUT / "chore-robotics-full-light.png",
        bg="white",
        tolerance=8,
    )
    remove_bg(
        SRC / "WhatsApp Image 2026-05-21 at 22.09.39 (1).jpeg",
        OUT / "chore-robotics-wordmark.png",
        bg="grey",
        tolerance=20,
    )

    # Extract just the hex icon mark from the wordmark (left portion) for compact uses.
    # Strategy: any pixel with non-zero alpha counts as "ink". Project onto the x-axis,
    # then walk from the left edge of the first ink column until we hit a gap of
    # >=gap_px empty columns — that gap separates the icon from the wordmark.
    src = Image.open(OUT / "chore-robotics-wordmark.png").convert("RGBA")
    arr = np.array(src)
    ink_any = arr[..., 3] > 16
    col_has_ink = ink_any.any(axis=0)
    xs_with_ink = np.where(col_has_ink)[0]
    if len(xs_with_ink) > 0:
        x_start = int(xs_with_ink[0])
        gap_px = 40
        x_end = src.size[0]
        run = 0
        for x in range(x_start, src.size[0]):
            if col_has_ink[x]:
                run = 0
            else:
                run += 1
                if run >= gap_px:
                    x_end = x - run + 1
                    break

        pad = 12
        x0 = max(0, x_start - pad)
        x1 = min(src.size[0], x_end + pad)
        # restrict to icon-only orange pixels for vertical bounds
        r, g, b, a = arr[..., 0], arr[..., 1], arr[..., 2], arr[..., 3]
        orange = (r > 200) & (g > 90) & (g < 180) & (b < 80) & (a > 0)
        ys = np.where(orange[:, x0:x1].any(axis=1))[0]
        if len(ys) > 0:
            y0 = max(0, int(ys.min()) - pad)
            y1 = min(src.size[1], int(ys.max()) + pad)
        else:
            y0, y1 = 0, src.size[1]
        mark = src.crop((x0, y0, x1, y1))
        mark.save(OUT / "chore-robotics-mark.png", "PNG", optimize=True)
        print(f"  wrote assets/logo/chore-robotics-mark.png  ({mark.size[0]}x{mark.size[1]})")

    print("done.")


if __name__ == "__main__":
    main()
