# Ice Slide Assist Plan

## Goal

Build an Openplanet plugin for Trackmania in three controlled stages:

1. V1: trustworthy live telemetry meter
2. V2: coaching/training feedback layer
3. V3: short-horizon prediction helper

Primary principle: telemetry accuracy first, coaching second, prediction last.

## Current project state

- V1 implementation phases 0-3 are complete.
- V1 Phase 4 (in-game validation and release tuning) is still open.
- V2 and V3 are not implemented yet.
- Core signal state transition logic is now separated for offline deterministic checks.

Detailed tracked status lives in `docs/feature-tracking.md`.

## Architecture strategy

Current structure:

- `info.toml`
- `IceSlideAssist.as`

When feature scope grows, split by concern:

- `Main.as`
- `Telemetry.as`
- `Math.as`
- `Hud.as`
- `Settings.as`
- `Predictor.as`

## Version scope

### V1 (telemetry meter)

In scope:

- signed slide angle
- lateral slip
- speed readout
- compact signed HUD meter
- reliability guards and smoothing

Done criteria:

- sign is correct left/right on known maps
- response is immediate enough while racing
- HUD is readable and low overhead

### V2 (coaching/training)

In scope:

- target angle bands by speed
- live state classification (optimal/under/over/unstable)
- trend signal
- short history graph

### V3 (prediction helper)

In scope:

- short-horizon projected path
- uncertainty/confidence fade
- optional steering response hints

## Execution order

1. Finish V1 Phase 4 validation and default tuning.
2. Lock V1 release notes and docs.
3. Implement V2 target model and trend/history features.
4. Implement V3 prediction only after V2 proves stable.

## Tracking system

Planning and backlog are tracked in Ruflo and mirrored in:

- `docs/feature-tracking.md`

Use that file and its task IDs as the canonical execution checklist.
