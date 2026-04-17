# Ice Slide Tuning Config

Central tuning profile for the project:

- `config/ice-slide-profile.json`

This file is the shared place to define what is considered good/bad ice-slide behavior.

## Current consumers

- `scripts/offline_ghost_preview.py` loads this profile by default (`--config`)
- Plugin settings in `IceSlideAssist.as` currently mirror the same thresholds and can be tuned in-game

## What can be tuned

- Telemetry gates:
  - minimum active speed
  - only-on-ice gating
  - smoothing/reset behavior
- Slide quality thresholds:
  - target angle band
  - under-slide and over-slide thresholds
  - speed-loss tolerance
  - oscillation tolerance
  - yaw-rate targets and oversteer threshold
  - direction-vs-velocity mismatch bands
- Strategy blocks for future use:
  - gear behavior hints
  - input smoothness guidance
  - uphill/downhill adaptations
  - surface transition windows (road->ice / ice->road)
  - phase descriptions (entry/mid/exit)

## Profile schema (main paths)

- `profile.name`
- `telemetry.speed.min_active_kmh`
- `telemetry.surface.only_show_on_ice`
- `telemetry.smoothing.alpha`
- `telemetry.smoothing.reset_when_inactive`
- `slide.angle.target_min_deg`
- `slide.angle.target_max_deg`
- `slide.angle.under_slide_deg`
- `slide.angle.over_slide_deg`
- `slide.speed.max_loss_kmh_per_sec`
- `slide.stability.max_oscillation_deg_per_sec`
- `slide.stability.yaw_rate.target_min_deg_per_sec`
- `slide.stability.yaw_rate.target_max_deg_per_sec`
- `slide.stability.yaw_rate.oversteer_deg_per_sec`
- `slide.trajectory.direction_velocity_mismatch.optimal_min_deg`
- `slide.trajectory.direction_velocity_mismatch.optimal_max_deg`
- `slide.surface.transition.road_to_ice_unstable_window_s`
- `slide.surface.transition.ice_to_road_regrip_window_s`

## Script usage

Default profile path:

```bash
python3 scripts/offline_ghost_preview.py
```

Custom profile path:

```bash
python3 scripts/offline_ghost_preview.py --config config/ice-slide-profile.json
```

## Notes

- Keep this file as the single source of truth for V2 tuning.
- If you adjust values in the profile, replicate them in plugin settings for in-game parity until direct plugin-side profile loading is added.
