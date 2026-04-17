# Ice Slide Assist (Trackmania Openplanet)

V1 goal: ship a reliable signed ice-slide telemetry meter before any coaching or prediction features.

## Current status

- Phase 0 bootstrap is complete.
- Phase 1 telemetry and signed-angle math are complete.
- Phase 2 reliability layer is complete (guards, confidence, EMA smoothing for angle + slip).
- Phase 3 compact HUD meter is complete (centered meter bar, zero marker, signed left/right fill, inactive dim state).
- Branch polish pass added robustness/perf/visual refinements (deadzone, optional ice-only gate, sign inversion toggle, jitter-aware confidence, cached meter bar rendering, angle severity coloring).
- Added optional ghost replay test mode that feeds deterministic synthetic frames from a `.Ghost.gbx` file into the same core evaluator and debug visuals.
- Added optional V2 coaching gauge layer (slide state + angle/speed/stability scores + efficiency) in HUD/debug output and offline preview script.

## Planned V1 deliverable

- Signed slide angle (left/right)
- Lateral slip
- Speed readout
- Compact HUD bar with center zero marker
- Guard rails for low speed / airborne / invalid state
- Lightweight smoothing

## Files

- `info.toml`
- `IceSlideAssist.as`
- `config/ice-slide-profile.json`
- `ghosts/` (`*.Ghost.gbx` replay files)
- `scripts/offline_ghost_preview.py`
- `docs/v1-execution-plan.md`
- `docs/v1-test-checklist.md`
- `docs/v1-phase2-validation.md`
- `docs/v1-phase3-validation.md`
- `docs/offline-ghost-preview.md`
- `docs/ice-slide-config.md`

## Next implementation step

Run Phase 4 in-game validation from `docs/v1-test-checklist.md` and tune defaults for release.

Planning and feature tracking are maintained in `docs/feature-tracking.md`.
Testing approach is documented in `docs/testing-strategy.md`.
Offline no-game preview usage, visual modes, and V2 gauge scoring details are documented in `docs/offline-ghost-preview.md`.
Shared ice-slide tuning profile details are documented in `docs/ice-slide-config.md`.
Ghost replay file organization and picker behavior are documented in `docs/offline-ghost-preview.md`.
