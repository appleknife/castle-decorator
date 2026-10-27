# Castle Decorator

A cozy pixel-art decorating game, being built for a friend who likes Stardew Valley mostly for the decorating.

Two tools, one palette, one item list. Everything is plain HTML/CSS/JS with no build step and no dependencies.

**Open the landing page:** `index.html`

---

## What's here

```
index.html          landing page linking to both tools
room-editor/        place furniture in a room, with depth, snapping and light
sprite-blender/     turn big art into a game-ready pixel sprite
serve.ps1           tiny local static server (needed for auto-save to work)
```

## The room editor

A 26×14 tile room at 16px per tile. 416×224 — a real game resolution.

- **Depth** — floor items move freely between the back wall and the front edge. Items lower on screen draw in front of items above them.
- **Magnets** — floor pieces pull to the back wall, the front edge, or the depth of a neighbour. Chairs pull to table seats. Edges click flush. Hold **Shift** to ignore magnets.
- **Lighting** — any placement can be a light source. Four overlapping lobes with surface awareness: a dim wash on the wall, a flattened pool on the floor. Day / Dusk toggle. Each light's origin can be set by clicking the item.
- **Music** — three tracks, loop and volume, plus a sound-effect volume.
- **Save** — auto-saves in the browser, or download a `.json` and load it back.

## The sprite blender

Drop in a photo, an AI render or an asset pack and get a pixel sprite on the shared 27-colour palette.

- **Pipeline** — area or nearest downscale, contrast clamp, palette quantise, despeckle, rim light, outline
- **Background removal** — flood-fill from the edges, with tolerance
- **Trim edge** — shaves the outermost pixel ring, which is what kills an opaque halo that alpha cut can't touch
- **Hand editing** — brush, dropper, erase, undo, in a layer over the computed result
- **Send to room** — fits the sprite into an item's tile box and writes it straight into the room editor

## Running it locally

`file://` pages get an opaque origin, so browser storage silently fails — no auto-save, no art persistence. Serve it instead:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File serve.ps1
```

Then open <http://localhost:8777/>.

Stop the server with:

```powershell
Get-CimInstance Win32_Process -Filter "Name='powershell.exe'" |
  Where-Object { $_.CommandLine -like '*serve.ps1*' } |
  ForEach-Object { Stop-Process -Id $_.ProcessId -Force }
```

## Put it on GitHub Pages

1. Settings → Pages → Source: **Deploy from a branch**, branch `main`, `/ (root)`
2. It goes live at `https://YOUR-USERNAME.github.io/REPO/`

The room editor opens the blender at `../sprite-blender/`, which resolves correctly both locally (served from the repo root) and on Pages.

## Known gaps

- **Custom art lives in the browser, not the room file.** `room.json` doesn't carry replaced sprites yet, so a shared room won't bring its custom art.
- **No collision.** `blocks` is carried on every item but nothing enforces it, so furniture can overlap.
- **The item list is duplicated.** The blender hardcodes the item ids and box sizes; they need to come from one shared file.
- **No packs.** There's no export format for sending furniture to another person yet.

## Item schema

An item is a type plus whatever it overrides:

```js
{ id: "table.oak", name: "Table", type: "table", w: 3, h: 2 }
```

Types carry the mechanics — surface, layer, blocking, drop sound, and anchors computed from width. Nine of them: `bench`, `chair`, `table`, `storage`, `rug`, `wall`, `plant`, `light`, `decor`.
