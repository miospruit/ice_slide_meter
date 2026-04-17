# Offline Ghost Preview (No Openplanet Required)

You can preview plugin behavior on macOS without running Trackmania/Openplanet.

This uses a standalone Python tool that:

- reads a `.Ghost.gbx` file
- derives deterministic synthetic test frames
- preserves phase continuity (entry/hold/exit) so angle behavior is sustained instead of random left-right flipping
- runs the same frame-evaluation logic used by the plugin (`EvaluateFrame` behavior)
- computes V2 coaching gauge values (slide state, angle/speed/stability scores, efficiency)
- renders an enhanced terminal HUD preview (zone gauge, score bars, trend lines)

## Run

From repo root:

```bash
python3 scripts/offline_ghost_preview.py
```

This loads the shared tuning profile from:

- `config/ice-slide-profile.json`
- scans ghosts from `ghosts/` and prompts you to pick one on startup

With explicit ghost file:

```bash
python3 scripts/offline_ghost_preview.py --ghost ghosts/Wirtual.Ghost.gbx
```

Use a custom ghost directory:

```bash
python3 scripts/offline_ghost_preview.py --ghost-dir ghosts
```

Compact racer view:

```bash
python3 scripts/offline_ghost_preview.py --view compact
```

Detailed analysis view:

```bash
python3 scripts/offline_ghost_preview.py --view full
```

## Visual features

- `full` view:
  - boxed dashboard
  - V2 state with optional color
  - efficiency + angle/speed/stability bars
  - zone angle gauge + signed meter
  - speed/slip/oscillation/confidence block
  - trend lines for angle and efficiency
- `compact` view:
  - minimal racer-focused layout
  - large angle gauge + efficiency bar
  - trend lines with less text
- color behavior:
  - colors enabled automatically on TTY terminals
  - disable with `--no-color`
- animation behavior:
  - clears and redraws per frame by default
  - use `--no-clear` for log-style output

## Gauge and scoring features

- Slide-state classification:
  - `Inactive`, `Entry`, `Slide`, `SlideGood`, `UnderSlide`, `OverSlide`, `Unstable`, `Exit`
- Scoring model:
  - `angleScore` from target-band fit
  - `speedScore` from speed-loss efficiency
  - `stabilityScore` from oscillation rate
  - `efficiencyScore = 0.50*angle + 0.30*speed + 0.20*stability`
- Derived telemetry shown in preview:
  - smooth slip angle
  - speed delta (km/h/s)
  - oscillation (deg/s)
  - confidence

## In-game V2 HUD features

- Toggle: `Enable V2 Ice Slide Gauge`
- Visual blocks in plugin HUD:
  - efficiency progress bar
  - angle score progress bar
  - speed score progress bar
  - stability score progress bar
  - state label with state color coding
- Existing signed-angle meter remains visible and acts as the primary directional gauge

## In-game ghost file picker

- Put replay files in `ghosts/` with extension `.Ghost.gbx`
- On plugin startup, a `Ghost Replay Source` window lets you choose the active replay file
- The debug window also includes:
  - ghost file dropdown
  - refresh list
  - reload replay data
  - reset playback
- Adding more files to `ghosts/` automatically creates more options after `Refresh Ghost List`

## Synthetic ghost replay features

- deterministic generation from ghost bytes
- sustained phase model (entry/hold/exit)
- sign-holding slide segments instead of random side flipping
- smoothed speed/angle/slip evolution for more realistic gauge behavior

## Useful options

- `--fps 20` render rate
- `--playback-speed 1.0` replay speed
- `--loops 2` replay passes
- `--config config/ice-slide-profile.json` tuning profile path
- `--ghost-dir ghosts` scan directory for ghost files
- `--ghost path/to/file.Ghost.gbx` bypass chooser and use this file directly
- `--view compact|full` preview layout
- `--meter-max-angle 45`
- `--min-speed 40`
- `--only-show-on-ice`
- `--smoothing-alpha 0.20`
- `--v2-target-min 15`
- `--v2-target-max 30`
- `--v2-under-angle 10`
- `--v2-over-angle 40`
- `--v2-max-speed-loss 22`
- `--v2-max-osc 140`
- `--no-reset-when-inactive`
- `--no-color` disable ANSI colors
- `--no-clear` keep full log instead of animated redraw

## Important scope note

This is a test preview harness. It does not decode full Trackmania ghost telemetry yet.
It maps ghost bytes into deterministic synthetic frames so you can test HUD and state behavior offline.
