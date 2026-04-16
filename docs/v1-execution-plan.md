# V1 Execution Plan

## Objective

Build a trustworthy live telemetry meter for ice sliding in Trackmania.

## Scope (in)

1. Signed slide angle from forward vs velocity direction
2. Lateral slip
3. Speed readout
4. HUD with compact meter and numeric value
5. Guard rails (low speed, airborne, invalid driving state)
6. Light smoothing

## Scope (out)

1. Target coaching bands (V2)
2. Trend/history coaching overlays (V2)
3. Path prediction and helper arcs (V3)

## Architecture

- Keep one script file for V1: `IceSlideAssist.as`
- Keep metadata in `info.toml`
- Keep docs/checklist in `docs/`

## Implementation phases

### Phase 0: Bootstrap (done)

- Plugin metadata and dependency setup
- Runtime loop skeleton
- HUD/debug shell with settings

### Phase 1: Telemetry and math

Status: done

Tasks:
- Pull player vehicle telemetry using `VehicleState`
- Extract/derive:
  - world position
  - velocity vector
  - forward vector
  - right vector
  - grounded/airborne flag
  - ice/surface flag (if available)
- Project forward + velocity to horizontal plane
- Compute signed angle using `atan2(dot(planeNormal, cross), dot)`
- Compute lateral slip using right-vector dot

Exit criteria:
- Direction sign is consistent with visual left/right slide
- Values are stable at race speed

### Phase 2: Reliability layer

Status: done

Tasks:
- Add invalid-state guards:
  - low speed threshold
  - tiny projected velocity
  - airborne
  - not driving
- Add confidence score in [0, 1]
- Apply EMA smoothing for angle and slip

Exit criteria:
- Reduced jitter at low speed
- No misleading active signal while airborne/inactive

### Phase 3: HUD completion

Status: done

Tasks:
- Replace text shell with compact meter UI:
  - title `ICE`
  - signed numeric angle
  - centered horizontal bar with zero marker
  - fill movement left/right based on sign
  - speed readout
  - dim inactive state
- Add scale and position settings support

Exit criteria:
- Readable in motion
- Responsive without clutter

### Phase 4: Validation and packaging

Status: next

Tasks:
- Validate against `docs/v1-test-checklist.md`
- Tune default thresholds/smoothing
- Finalize README usage notes

Exit criteria:
- V1 acceptance checklist passes

## Acceptance checklist

- Signed direction is correct on known ice corners
- Angle reacts immediately to slide transitions
- Low-speed/airborne behavior is not misleading
- HUD is readable at race pace
- FPS impact is negligible

## Risks and mitigations

1. Wrong projection plane for some maps
   - Start with horizontal plane in V1, defer local plane to post-V1
2. Ice detection uncertainty
   - Do not block V1 on perfect auto-detect; use debug/manual behavior when needed
3. UI overload
   - Keep compact meter only for V1
