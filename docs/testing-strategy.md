# Testing Strategy (V1 -> V3)

This project uses a hybrid strategy:

1. deterministic offline checks for pure logic
2. in-game validation for runtime behavior and UX

This is the most practical approach for Openplanet plugins where part of the system depends on Trackmania runtime state.

## Why hybrid testing

Offline checks can prove core math and state rules, but cannot prove what Trackmania sends at runtime or how the HUD feels while racing.

### Offline checks can verify

- signed-angle math behavior
- deadzone behavior
- smoothing behavior
- confidence scoring behavior
- V2 slide-state classification behavior
- V2 angle/speed/stability/efficiency scoring behavior
- active/inactive gate rules and inactive reasons

### In-game checks are still required

- real sign orientation on live maps
- visual readability at race pace
- ice-contact edge cases and transitions
- frame-time impact during actual gameplay

## Testable architecture in code

`IceSlideAssist.as` now separates runtime input collection from core frame evaluation:

- runtime layer:
  - `TryGetSignalInputs(...)`
  - `Tick(...)` input gathering from `VehicleState`
- core evaluation layer:
  - `CoreConfig`
  - `FrameInputs`
  - `FrameOutput`
  - `EvaluateFrame(...)`

The goal is to make frame-level behavior testable with synthetic input frames.

## Built-in offline self-test harness

The debug window now includes a `Run Offline Self-Tests` action.

Covered checks:

- signed angle sanity (`0`, `+45`, `-45`)
- deadzone suppression and passthrough
- active-state smoothing path
- invalid-state gating and confidence suppression

How to run:

1. Enable `Debug Mode` in plugin settings.
2. Open the debug window in-game.
3. Click `Run Offline Self-Tests`.
4. Inspect the multiline test report for pass/fail entries.

## Full offline preview without the game

Use `scripts/offline_ghost_preview.py` to run a terminal-based HUD simulation on macOS
without Openplanet/Trackmania.

This replays deterministic synthetic frames derived from a `.Ghost.gbx` file and runs
the same frame-state evaluation behavior used in the plugin.
The same run now prints V2 coaching state and efficiency scoring values.

Docs: `docs/offline-ghost-preview.md`
Tuning profile: `config/ice-slide-profile.json` (schema in `docs/ice-slide-config.md`)

## Execution workflow

1. Run offline self-tests after core math/state changes.
2. If passing, run `docs/v1-test-checklist.md` on real maps.
3. Record map-level pass/fail observations and threshold tuning notes.
4. Apply tuning changes and repeat both layers.

## Limitations and next upgrades

- Current self-tests are scenario-based and manual-triggered.
- A ghost replay test mode now exists and can derive deterministic synthetic test frames from a `.Ghost.gbx` file.
- The ghost replay path is intentionally non-invasive: it reuses `EvaluateFrame(...)` and only runs when the setting is enabled.
- The current ghost implementation does not decode full Trackmania ghost telemetry yet; it maps ghost bytes into stable synthetic inputs for regression-style checks.
- For V2/V3, keep predictor/coaching logic in pure functions first, then attach UI/runtime layers.
