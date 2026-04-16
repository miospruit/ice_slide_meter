# V1 Phase 2 Validation (Offline)

This validation was done without a local Trackmania/Openplanet runtime.

## What was validated

- Telemetry integration points are in place with `VehicleState::ViewingPlayerState()` and `VehicleState::GetViewingPlayer()`.
- Reliability guards are active for:
  - not driving
  - airborne
  - low planar velocity
  - below minimum speed
- Confidence is bounded to `[0, 1]` and reduced when not on clear ice contact.
- Smoothing is applied to both angle and lateral slip, with optional reset while inactive.

## Math sanity check (independent)

Signed-angle formula was tested with a standalone script using the same `atan2(dot(planeNormal, cross), dot)` approach.

Observed outputs:

- straight: `+0.00 deg`
- right drift: `+45.00 deg`
- left drift: `-45.00 deg`
- reverse: `+180.00 deg`

Interpretation:

- Sign direction is internally consistent for left/right drift examples.
- Runtime sign orientation may still need one in-game check and optional inversion, depending on Trackmania axis conventions in practice.

## Not validated yet

- In-game behavior on real maps
- Visual readability under motion
- FPS impact while racing

## Next validation step

Use `docs/v1-test-checklist.md` for in-game pass/fail once Trackmania is available.
