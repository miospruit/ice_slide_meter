# AGENTS.md

## Current State
- This is an active Openplanet plugin for Trackmania called "Ice Slide Assist".
- The plugin provides live ice-slide telemetry and coaching via a HUD overlay.
- V1 core telemetry (signed angle, lateral slip, speed, guards, smoothing) is implemented.
- V2 coaching layer (slide state classification, efficiency scoring) is partially implemented.
- In-game validation has been performed but the gauge needs refinement.

## Files
- `info.toml` — Plugin metadata and dependencies
- `IceSlideAssist.as` — Main plugin source (AngelScript)
- `config/ice-slide-profile.json` — Shared tuning profile (consumed by offline preview script)
- `ghosts/` — `.Ghost.gbx` replay files for offline testing
- `scripts/offline_ghost_preview.py` — Terminal-based HUD simulation without the game
- `docs/` — Planning, validation, and feature tracking docs

## Working Rules
- This plugin uses the `VehicleState` Openplanet dependency.
- The plugin uses `nvg` (NanoVG) for custom circular gauge rendering in `Render()`.
- ImGui (`UI::`) is used only for windows, debug UI, and settings interface in `RenderInterface()`.
- The `RenderMenu()` toggle controls HUD visibility via a persistent setting.

## Architecture
- `Render()` — nvg overlay drawing (circular gauge, needle, coaching text)
- `RenderInterface()` — ImGui windows (debug, ghost picker)
- `RenderMenu()` — Openplanet plugin menu toggle
- Core logic is in `ISA` namespace with separated `EvaluateFrame()` for testability.

## Build / Test
- No build step required; Openplanet loads AngelScript directly.
- Offline tests: run `python3 scripts/offline_ghost_preview.py`
- In-game: enable plugin in Openplanet, load an ice map, check HUD.

## Version History
- 0.1.0 — Initial V1 telemetry meter with ASCII bar
- Next — Circular nvg gauge with coaching hints and state hysteresis
