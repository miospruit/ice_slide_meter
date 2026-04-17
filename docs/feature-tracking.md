# Feature Tracking (Ruflo)

This file is the cleaned planning source of truth for feature status and next work.

## Current feature set (implemented)

Status: V1 implementation complete, Phase 4 validation pending.

- Signed slide angle from forward vs velocity direction
- Lateral slip from velocity dot right vector
- Speed readout and active/inactive state
- Reliability guards (not driving, airborne, low planar velocity, minimum speed)
- Confidence score in [0, 1] based on speed, ice contact, and jitter
- EMA smoothing for angle and slip with optional inactive reset
- Compact HUD meter (center marker, signed left/right fill)
- Angle severity colors (good/warn/high)
- Optional robustness controls (deadzone, ice-only gate, sign inversion)
- Debug window with telemetry and gate diagnostics
- Core frame evaluator split (`EvaluateFrame`) for deterministic logic testing
- Built-in offline self-test harness in debug window

## What we can do now

- Give live, directional ice-slide telemetry while driving
- Suppress misleading output when confidence/state is invalid
- Run with configurable HUD scale/position and tuning thresholds
- Support manual testing and calibration without prediction/coaching layers
- Run offline deterministic self-tests before in-game validation passes

## Remaining roadmap

### V1 completion (release readiness)

1. `task-1776343057828-k4sorn` (high): run in-game Phase 4 validation using `docs/v1-test-checklist.md`
2. `task-1776343057893-m20nzg` (high): tune defaults from validation results
3. `task-1776343057918-hhhl88` (normal): finalize release notes and usage docs

### V2 (coaching/training overlay)

1. `task-1776343057935-kaw5ut` (normal): target-band model + live classification
2. `task-1776343057949-x8yn8f` (normal): trend indicator + short history graph

### V3 (prediction/path helper)

1. `task-1776343057962-trzui5` (normal): short-horizon predictor with uncertainty fade

## Tracking policy

- Keep status here aligned with README status and docs validation files
- Track concrete execution work in Ruflo task IDs listed above
- Close V1 tasks before starting V2/V3 implementation
