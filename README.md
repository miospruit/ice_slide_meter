# Ice Slide Assist (Trackmania Openplanet)

V1 goal: ship a reliable signed ice-slide telemetry meter before any coaching or prediction features.

## Current status

- Phase 0 bootstrap is complete.
- Phase 1 telemetry and signed-angle math are complete.
- Phase 2 reliability layer is complete (guards, confidence, EMA smoothing for angle + slip).

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

## Next implementation step

Implement Phase 3 compact HUD meter visuals (centered bar, zero marker, signed fill direction, dim inactive state).
