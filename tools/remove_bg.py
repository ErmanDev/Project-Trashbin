"""Remove the flat background from generated character sprites.

Uses an edge-connected flood fill with a colour tolerance: only pixels that are
similar to the sampled background colour AND reachable from the image border are
made transparent. This avoids punching holes in the character when interior
colours happen to match the background.
"""

import os
import sys
from collections import deque

from PIL import Image

# (filename, tolerance) pairs. Tolerance is squared-distance friendly value.
TARGETS = [
    ("char_boy1.png", 55),
    ("char_boy2.png", 55),
    ("char_girl1.png", 55),
    ("char_girl2.png", 55),
    ("char_mayor.png", 48),
]


def sample_bg(px, w, h):
    """Average the four corner regions to estimate the background colour."""
    pts = []
    m = 6
    for cx, cy in ((0, 0), (w - 1, 0), (0, h - 1), (w - 1, h - 1)):
        for dx in range(m):
            for dy in range(m):
                x = min(max(cx + (dx if cx == 0 else -dx), 0), w - 1)
                y = min(max(cy + (dy if cy == 0 else -dy), 0), h - 1)
                pts.append(px[x, y])
    r = sum(p[0] for p in pts) // len(pts)
    g = sum(p[1] for p in pts) // len(pts)
    b = sum(p[2] for p in pts) // len(pts)
    return (r, g, b)


def close_enough(c, bg, tol_sq):
    dr = c[0] - bg[0]
    dg = c[1] - bg[1]
    db = c[2] - bg[2]
    return (dr * dr + dg * dg + db * db) <= tol_sq


def remove_bg(path_in, path_out, tol):
    img = Image.open(path_in).convert("RGBA")
    w, h = img.size
    px = img.load()
    bg = sample_bg(px, w, h)
    tol_sq = tol * tol

    visited = bytearray(w * h)
    q = deque()

    def consider(x, y):
        idx = y * w + x
        if visited[idx]:
            return
        visited[idx] = 1
        c = px[x, y]
        if close_enough(c, bg, tol_sq):
            q.append((x, y))

    for x in range(w):
        consider(x, 0)
        consider(x, h - 1)
    for y in range(h):
        consider(0, y)
        consider(w - 1, y)

    while q:
        x, y = q.popleft()
        px[x, y] = (0, 0, 0, 0)
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if 0 <= nx < w and 0 <= ny < h:
                consider(nx, ny)

    img.save(path_out)
    cleared = sum(visited)  # approx; visited includes non-matching border too
    print(f"{os.path.basename(path_out)}: bg={bg} tol={tol} -> saved")


def main():
    base = sys.argv[1]
    for name, tol in TARGETS:
        src = os.path.join(base, name)
        dst = os.path.join(base, name.replace(".png", "_cutout.png"))
        if not os.path.exists(src):
            print(f"skip missing {src}")
            continue
        remove_bg(src, dst, tol)


if __name__ == "__main__":
    main()
