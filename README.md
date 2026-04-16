# Ice Slide Assist (Trackmania Openplanet)

V1 goal: ship a reliable signed ice-slide telemetry meter before any coaching or prediction features.

## Current status

- Phase 0 bootstrap is complete.
- Phase 1 telemetry and signed-angle math are complete.
- Phase 2 reliability layer is complete (guards, confidence, EMA smoothing for angle + slip).
- Phase 3 compact HUD meter is complete (centered meter bar, zero marker, signed left/right fill, inactive dim state).
- Branch polish pass added robustness/perf/visual refinements (deadzone, optional ice-only gate, sign inversion toggle, jitter-aware confidence, cached meter bar rendering, angle severity coloring).

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
- `docs/v1-execution-plan.md`
- `docs/v1-test-checklist.md`
- `docs/v1-phase2-validation.md`
- `docs/v1-phase3-validation.md`

## Next implementation step

Run Phase 4 in-game validation from `docs/v1-test-checklist.md` and tune defaults for release.
