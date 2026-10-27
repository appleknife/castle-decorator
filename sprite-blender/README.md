# Sprite Blender

Turn a big piece of art into a cohesive pixel-art sprite — then fix the last 10% by hand.

Everything is in one HTML file with no dependencies and no build step. Open `index.html` and drag an image onto it.

---

## Why

Pixel art is a series of small deliberate decisions — where the one-pixel highlight goes, which edge gets an outline, where to dither instead of shade. Downsampling destroys exactly those decisions.

So this doesn't try to be clever. It does the mechanical part (downscale, snap to palette, unify the light) and then hands the sprite back to you with a brush. The blender gets you to 90%; the last 10% is the part that makes it look like it belongs in a game.

The real job is **harmony**: bought asset packs, AI concepts and your own scribbles all landing in the same world, because they share one palette, one light direction and one outline policy.

## The one rule that matters

**Source should be roughly 4–8× your target height.** Below 2.5× you get mush; past 16× you are throwing away detail that cannot survive. The ratio badge on the result bar turns amber and red outside the band, so you don't have to guess.

Judging at 1× is the other one — the "1× true size" panel exists because everything looks fine zoomed in and falls apart at actual size.

## Pipeline

1. **Area** downscale (box-average, for photos and AI renders) or **Nearest** (for sources that are already pixel art) — repeated halving then a final weighted average, so it stays fast on huge images
2. **Contrast** clamp — downsampling always crushes midtones
3. **Quantise** to the palette, optionally with 4×4 or 8×8 ordered (Bayer) dithering
4. **Despeckle** — drops stray clusters; thin details shatter at big ratios, and this sweeps them up before the outline wraps each orphan in a dark block
5. **Rim light** on the top-left silhouette
6. **Outline** — full, or shadow-side only, leaving the lit edges open

Rim light on the lit side plus outline on the shadow side gives every asset the same light direction, which is most of what makes a set look like a set.

## Palettes

Four to start from — Cozy Oak, Candlelit, Moonlit Stone, Orchard — or extract from the source with median cut, or hand-build one.

- Click a swatch to paint with it
- Shift-click to edit its colour
- Hover and hit `×` to remove

## Hand editing

The zoom canvas is an editor, and edits live in a layer **on top of** the computed result — so the sliders stay live and a brush stroke is never wiped by a contrast tweak. While painting it redraws from a cached pristine copy rather than re-running the pipeline, so it stays responsive.

| Tool | Key | |
|---|---|---|
| Brush | `B` | click or drag; fast drags interpolate with Bresenham |
| Dropper | `P` | picks the colour under the cursor |
| Erase | `E` | paints transparency |
| Undo | `Ctrl+Z` | one step per stroke, not per pixel |

An amber box follows the cursor so you always know which pixel you are about to hit.

Edit layers are keyed to the canvas size, so changing target height — or toggling Outline, which grows the canvas by a pixel on each side — starts a fresh layer. The old one is still there if you switch back. **Reset edits** clears the current layer.

## Scale note

64px is the default and a good house scale for furniture: at a 16px tile that is a substantial four-tile wardrobe or bench. The **Scene** panel builds a room around whatever you have made — one tile of headroom, one of floor — and scales to fit, so a tall bookshelf is never cropped. The caption reports the real zoom and the room size in tiles.

Small props (candles, books) want their own pass at 16 or 32. Each size keeps its own edit layer, so those do not interfere.

## Export

- **PNG 1×** — the actual size, use this in the game
- **PNG 8×** — nearest-neighbour upscale for showing people
- **Copy palette** — the palette as JSON
- **Copy item stub** — a starter entry for the item definition format

## Run it locally

Just open `index.html`. It works from `file://` — no server needed.

For a Pages-style test, a plain server also works:

```bash
python -m http.server 8000
```

## Put it on GitHub Pages

1. Settings → Pages
2. Source: **Deploy from a branch**, branch `main`, folder `/ (root)`
3. Save — it goes live at `https://YOUR-USERNAME.github.io/sprite-blender/`

## Layout

```
index.html      the whole tool: markup, styles and script
```

Single file, on purpose — it is a tool you can email, fork, or drop next to any other project.
