#!/usr/bin/env python3
"""Offline ghost preview for Ice Slide Assist.

This tool runs fully outside Openplanet/Trackmania and renders a terminal
preview of the plugin HUD behavior using deterministic synthetic frames derived
from a .Ghost.gbx file.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
from collections import deque
from dataclasses import dataclass


def clamp(v: float, lo: float, hi: float) -> float:
    return max(lo, min(v, hi))


def clamp01(v: float) -> float:
    return clamp(v, 0.0, 1.0)


def clamp_int(v: int, lo: int, hi: int) -> int:
    return max(lo, min(v, hi))


def lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def effective_alpha(base_alpha: float, dt: float) -> float:
    a = clamp01(base_alpha)
    steps = max(1.0, dt * 60.0)
    return 1.0 - pow(1.0 - a, steps)


def build_meter_bar(angle_deg: float, max_abs_deg: float, half_width: int) -> str:
    safe_max = max(1.0, max_abs_deg)
    clamped_angle = clamp(angle_deg, -safe_max, safe_max)
    norm = clamped_angle / safe_max

    left_fill = 0
    right_fill = 0
    if norm < 0:
        left_fill = int(round(abs(norm) * half_width))
    else:
        right_fill = int(round(norm * half_width))

    left_fill = clamp_int(left_fill, 0, half_width)
    right_fill = clamp_int(right_fill, 0, half_width)

    left = []
    for i in range(half_width):
        is_fill = i >= (half_width - left_fill)
        if not is_fill:
            left.append("-")
        elif i == (half_width - left_fill):
            left.append("<")
        else:
            left.append("=")

    right = []
    for i in range(half_width):
        is_fill = i < right_fill
        if not is_fill:
            right.append("-")
        elif i == (right_fill - 1):
            right.append(">")
        else:
            right.append("=")

    return "[" + "".join(left) + "|" + "".join(right) + "]"


def build_meter_scale_label(max_abs_deg: float, half_width: int) -> str:
    safe_half = max(1, half_width)
    safe_max = max(1.0, max_abs_deg)
    left_label = f"-{safe_max:.0f}"
    center_label = "0"
    right_label = f"+{safe_max:.0f}"

    left_gap = max(1, safe_half - len(left_label))
    right_gap = max(1, safe_half - len(right_label))
    return left_label + (" " * left_gap) + center_label + (" " * right_gap) + right_label


def state_color_code(slide_state: str) -> str:
    if slide_state == "SlideGood":
        return "32"
    if slide_state in {"Entry", "Exit", "Slide"}:
        return "36"
    if slide_state == "UnderSlide":
        return "33"
    if slide_state in {"OverSlide", "Unstable"}:
        return "31"
    return "37"


def with_color(text: str, ansi_code: str, enabled: bool) -> str:
    if not enabled:
        return text
    return f"\033[{ansi_code}m{text}\033[0m"


def score_bar(score: float, width: int = 22) -> str:
    clamped = clamp01(score)
    fill = int(round(clamped * width))
    return "[" + ("#" * fill) + ("-" * (width - fill)) + "]"


def angle_zone_bar(angle_deg: float, max_abs_deg: float, width: int = 49) -> str:
    safe_max = max(1.0, max_abs_deg)
    zones = []
    for i in range(width):
        x = -safe_max + (2.0 * safe_max * i / max(1, width - 1))
        ax = abs(x)
        if ax < 10.0:
            zones.append(".")
        elif ax <= 30.0:
            zones.append("=")
        elif ax <= 40.0:
            zones.append("+")
        else:
            zones.append("!")

    norm = clamp(angle_deg, -safe_max, safe_max) / safe_max
    pointer = int(round((norm + 1.0) * 0.5 * (width - 1)))
    pointer = clamp_int(pointer, 0, width - 1)
    zones[pointer] = "^"
    return "[" + "".join(zones) + "]"


def build_trend_line(values: deque[float], lo: float, hi: float, width: int = 40) -> str:
    if not values:
        return "." * width
    palette = ".:-=+*#%@"
    if len(values) <= width:
        sample = list(values)
    else:
        step = len(values) / width
        sample = [values[int(i * step)] for i in range(width)]

    out = []
    span = max(1e-6, hi - lo)
    for v in sample:
        t = clamp01((v - lo) / span)
        idx = clamp_int(int(t * (len(palette) - 1)), 0, len(palette) - 1)
        out.append(palette[idx])
    if len(out) < width:
        out.extend(["."] * (width - len(out)))
    return "".join(out)


@dataclass
class CoreConfig:
    min_speed_kmh: float = 40.0
    only_show_on_ice: bool = False
    smoothing_alpha: float = 0.20
    reset_when_inactive: bool = True
    v2_target_angle_min_deg: float = 15.0
    v2_target_angle_max_deg: float = 30.0
    v2_under_slide_angle_deg: float = 10.0
    v2_over_slide_angle_deg: float = 40.0
    v2_max_speed_loss_kmh_per_sec: float = 22.0
    v2_max_oscillation_deg_per_sec: float = 140.0


@dataclass
class ProfileMeta:
    name: str = "default"
    description: str = ""


@dataclass
class FrameInput:
    dt: float
    speed_kmh: float
    prev_speed_kmh: float
    raw_angle_deg: float
    prev_raw_angle_deg: float
    lateral_slip: float
    prev_smooth_angle_deg: float
    prev_smooth_lateral_slip: float
    prev_smooth_speed_delta_kmh_per_sec: float
    is_driving: bool
    is_airborne: bool
    is_on_ice: bool
    has_signal: bool


@dataclass
class FrameOutput:
    smooth_angle_deg: float
    smooth_lateral_slip: float
    speed_delta_kmh_per_sec: float
    smooth_speed_delta_kmh_per_sec: float
    angle_oscillation_deg_per_sec: float
    confidence: float
    angle_score: float
    speed_score: float
    stability_score: float
    efficiency_score: float
    slide_state: str
    is_active: bool
    inactive_reason: str


@dataclass
class GhostFrame:
    speed_kmh: float
    raw_angle_deg: float
    lateral_slip: float
    is_driving: bool
    is_airborne: bool
    is_on_ice: bool
    has_signal: bool


def compute_confidence_values(
    is_driving: bool,
    is_airborne: bool,
    has_signal: bool,
    is_on_ice: bool,
    speed_kmh: float,
    raw_angle_deg: float,
    smooth_angle_deg: float,
    config: CoreConfig,
) -> float:
    if (not is_driving) or is_airborne or (not has_signal) or (config.only_show_on_ice and not is_on_ice):
        return 0.0
    speed_factor = clamp01((speed_kmh - config.min_speed_kmh) / 80.0)
    ice_factor = 1.0 if is_on_ice else 0.65
    jitter = abs(raw_angle_deg - smooth_angle_deg)
    jitter_factor = 1.0 - clamp01(jitter / 25.0)
    return clamp01(speed_factor * ice_factor * jitter_factor)


def score_angle_band(abs_angle_deg: float, config: CoreConfig) -> float:
    under = max(0.1, config.v2_under_slide_angle_deg)
    target_min = max(under, config.v2_target_angle_min_deg)
    target_max = max(target_min, config.v2_target_angle_max_deg)
    over = max(target_max + 0.1, config.v2_over_slide_angle_deg)

    if abs_angle_deg <= under:
        return 0.35 * clamp01(abs_angle_deg / under)
    if abs_angle_deg < target_min:
        return lerp(0.35, 1.0, clamp01((abs_angle_deg - under) / max(0.1, target_min - under)))
    if abs_angle_deg <= target_max:
        return 1.0
    if abs_angle_deg < over:
        return clamp01(1.0 - (abs_angle_deg - target_max) / max(0.1, over - target_max))
    return 0.0


def score_speed_efficiency(speed_delta_kmh_per_sec: float, config: CoreConfig) -> float:
    if speed_delta_kmh_per_sec >= 0.0:
        return 1.0
    max_loss = max(1.0, config.v2_max_speed_loss_kmh_per_sec)
    return clamp01(1.0 - abs(speed_delta_kmh_per_sec) / max_loss)


def score_stability(angle_oscillation_deg_per_sec: float, config: CoreConfig) -> float:
    max_osc = max(10.0, config.v2_max_oscillation_deg_per_sec)
    return clamp01(1.0 - angle_oscillation_deg_per_sec / max_osc)


STATE_HYSTERESIS_FRAMES = 6
_g_pending_state = ""
_g_state_timer = 0
_g_last_state = "Inactive"


def classify_slide_state(
    is_active: bool,
    smooth_angle_deg: float,
    prev_smooth_angle_deg: float,
    speed_delta_kmh_per_sec: float,
    angle_score: float,
    speed_score: float,
    stability_score: float,
    config: CoreConfig,
) -> str:
    global _g_pending_state, _g_state_timer, _g_last_state

    if not is_active:
        raw = "Inactive"
    else:
        abs_angle = abs(smooth_angle_deg)
        prev_abs_angle = abs(prev_smooth_angle_deg)
        target_min = max(0.0, config.v2_target_angle_min_deg)
        target_max = max(target_min, config.v2_target_angle_max_deg)
        under = max(0.0, config.v2_under_slide_angle_deg)
        over = max(target_max, config.v2_over_slide_angle_deg)

        if stability_score < 0.30:
            raw = "Unstable"
        elif abs_angle > over and speed_delta_kmh_per_sec < -6.0:
            raw = "OverSlide"
        elif prev_abs_angle < under and abs_angle >= under and abs_angle < target_min:
            raw = "Entry"
        elif abs_angle < under:
            raw = "UnderSlide"
        elif prev_abs_angle >= target_min and abs_angle < target_min:
            raw = "Exit"
        elif (
            target_min <= abs_angle <= target_max
            and angle_score > 0.8
            and speed_score > 0.45
            and stability_score > 0.45
        ):
            raw = "SlideGood"
        else:
            raw = "Slide"

    # Apply hysteresis
    if raw != _g_last_state:
        if raw != _g_pending_state:
            _g_pending_state = raw
            _g_state_timer = 0
        else:
            _g_state_timer += 1
            if _g_state_timer >= STATE_HYSTERESIS_FRAMES:
                _g_last_state = raw
                _g_pending_state = ""
                _g_state_timer = 0
    else:
        _g_pending_state = ""
        _g_state_timer = 0

    return _g_last_state


def evaluate_frame(frame_input: FrameInput, config: CoreConfig) -> FrameOutput:
    speed_ok = frame_input.speed_kmh >= config.min_speed_kmh
    surface_ok = (not config.only_show_on_ice) or frame_input.is_on_ice
    state_ok = frame_input.is_driving and (not frame_input.is_airborne) and frame_input.has_signal and surface_ok
    is_active = state_ok and speed_ok

    inactive_reason = ""
    if not frame_input.is_driving:
        inactive_reason = "not driving"
    elif frame_input.is_airborne:
        inactive_reason = "airborne"
    elif not frame_input.has_signal:
        inactive_reason = "low planar velocity"
    elif not surface_ok:
        inactive_reason = "not on ice"
    elif not speed_ok:
        inactive_reason = "below min speed"

    dt = max(0.0, frame_input.dt)
    alpha = effective_alpha(config.smoothing_alpha, dt)
    smooth_angle = frame_input.prev_smooth_angle_deg
    smooth_slip = frame_input.prev_smooth_lateral_slip
    smooth_speed_delta = frame_input.prev_smooth_speed_delta_kmh_per_sec

    if is_active:
        smooth_angle = lerp(frame_input.prev_smooth_angle_deg, frame_input.raw_angle_deg, alpha)
        smooth_slip = lerp(frame_input.prev_smooth_lateral_slip, frame_input.lateral_slip, alpha)
    elif config.reset_when_inactive:
        reset_alpha = effective_alpha(0.10, dt)
        smooth_angle = lerp(frame_input.prev_smooth_angle_deg, 0.0, reset_alpha)
        smooth_slip = lerp(frame_input.prev_smooth_lateral_slip, 0.0, reset_alpha)

    speed_delta = (frame_input.speed_kmh - frame_input.prev_speed_kmh) / dt if dt > 1e-6 else 0.0
    delta_alpha = effective_alpha(0.18, dt)
    smooth_speed_delta = lerp(frame_input.prev_smooth_speed_delta_kmh_per_sec, speed_delta, delta_alpha)
    angle_oscillation = abs(frame_input.raw_angle_deg - frame_input.prev_raw_angle_deg) / dt if dt > 1e-6 else 0.0

    abs_angle = abs(smooth_angle)
    angle_score = score_angle_band(abs_angle, config)
    speed_score = score_speed_efficiency(smooth_speed_delta, config)
    stability_score = score_stability(angle_oscillation, config)
    efficiency_score = clamp01(0.50 * angle_score + 0.30 * speed_score + 0.20 * stability_score)
    slide_state = classify_slide_state(
        is_active,
        smooth_angle,
        frame_input.prev_smooth_angle_deg,
        smooth_speed_delta,
        angle_score,
        speed_score,
        stability_score,
        config,
    )

    confidence = compute_confidence_values(
        frame_input.is_driving,
        frame_input.is_airborne,
        frame_input.has_signal,
        frame_input.is_on_ice,
        frame_input.speed_kmh,
        frame_input.raw_angle_deg,
        smooth_angle,
        config,
    )

    if not is_active:
        angle_score = 0.0
        speed_score = 0.0
        stability_score = 0.0
        efficiency_score = 0.0

    return FrameOutput(
        smooth_angle_deg=smooth_angle,
        smooth_lateral_slip=smooth_slip,
        speed_delta_kmh_per_sec=speed_delta,
        smooth_speed_delta_kmh_per_sec=smooth_speed_delta,
        angle_oscillation_deg_per_sec=angle_oscillation,
        confidence=confidence,
        angle_score=angle_score,
        speed_score=speed_score,
        stability_score=stability_score,
        efficiency_score=efficiency_score,
        slide_state=slide_state,
        is_active=is_active,
        inactive_reason=inactive_reason,
    )


def derive_ghost_frames(data: bytes) -> list[GhostFrame]:
    data_len = len(data)
    if data_len < 64:
        raise ValueError("Ghost file is too small to derive test frames")

    frame_count = clamp_int(data_len // 3, 240, 1800)
    cursor = 0

    def next_byte() -> int:
        nonlocal cursor
        if data_len <= 0:
            return 0
        idx = cursor % data_len
        cursor = (idx + 1) % data_len
        return data[idx]

    frames: list[GhostFrame] = []
    sim_speed_kmh = 80.0 + (next_byte() / 255.0) * 110.0
    sim_angle_deg = 0.0
    sim_slip = 0.0
    slide_sign = 1 if next_byte() > 127 else -1
    phase_frames_left = 40 + (next_byte() % 80)
    in_slide_phase = False
    target_abs_angle = 0.0
    target_speed_kmh = sim_speed_kmh

    for _ in range(frame_count):
        if phase_frames_left <= 0:
            phase_selector = next_byte()
            in_slide_phase = phase_selector > 70
            if in_slide_phase:
                sign_selector = next_byte()
                if sign_selector > 90:
                    slide_sign = 1 if sign_selector > 170 else -1
                shape = next_byte() / 255.0
                target_abs_angle = 12.0 + shape * 22.0
                target_speed_kmh = 90.0 + (next_byte() / 255.0) * 140.0
                phase_frames_left = 90 + (next_byte() % 220)
            else:
                target_abs_angle = (next_byte() / 255.0) * 5.0
                target_speed_kmh = 70.0 + (next_byte() / 255.0) * 120.0
                phase_frames_left = 25 + (next_byte() % 95)

        phase_frames_left -= 1

        target_angle = slide_sign * target_abs_angle if in_slide_phase else 0.0
        angle_alpha = 0.08 if in_slide_phase else 0.12
        sim_angle_deg = lerp(sim_angle_deg, target_angle, angle_alpha)
        if (not in_slide_phase) and abs(sim_angle_deg) < 0.2:
            sim_angle_deg = 0.0

        sim_speed_kmh = lerp(sim_speed_kmh, target_speed_kmh, 0.04)
        sim_slip = lerp(sim_slip, (sim_angle_deg / 45.0) * 5.0, 0.11)

        rare_airborne = next_byte() > 252
        has_noise_signal = next_byte() > 8

        speed_kmh = clamp(sim_speed_kmh, 20.0, 260.0)
        raw_angle_deg = clamp(sim_angle_deg, -48.0, 48.0)
        lateral_slip = clamp(sim_slip, -7.0, 7.0)
        is_on_ice = in_slide_phase or next_byte() > 15
        is_airborne = (not in_slide_phase) and rare_airborne
        has_signal = speed_kmh > 24.0 and (in_slide_phase or has_noise_signal or abs(raw_angle_deg) > 0.6)
        is_driving = next_byte() > 1

        if abs(raw_angle_deg) < 0.4:
            raw_angle_deg = 0.0
        if not has_signal:
            raw_angle_deg = 0.0
            lateral_slip = 0.0

        frames.append(
            GhostFrame(
                speed_kmh=speed_kmh,
                raw_angle_deg=raw_angle_deg,
                lateral_slip=lateral_slip,
                is_driving=is_driving,
                is_airborne=is_airborne,
                is_on_ice=is_on_ice,
                has_signal=has_signal,
            )
        )

    return frames


def clear_screen(enabled: bool) -> None:
    if enabled:
        sys.stdout.write("\x1b[2J\x1b[H")
        sys.stdout.flush()


def _read_nested_float(data: dict, path: tuple[str, ...], fallback: float) -> float:
    cur = data
    for key in path:
        if not isinstance(cur, dict) or key not in cur:
            return fallback
        cur = cur[key]
    try:
        return float(cur)
    except (TypeError, ValueError):
        return fallback


def _read_nested_bool(data: dict, path: tuple[str, ...], fallback: bool) -> bool:
    cur = data
    for key in path:
        if not isinstance(cur, dict) or key not in cur:
            return fallback
        cur = cur[key]
    if isinstance(cur, bool):
        return cur
    return fallback


def load_profile(path: str, fallback: CoreConfig) -> tuple[CoreConfig, ProfileMeta]:
    if not path:
        return fallback, ProfileMeta()
    if not os.path.exists(path):
        return fallback, ProfileMeta(name="default", description=f"profile not found: {path}")

    with open(path, "r", encoding="utf-8") as fp:
        raw = json.load(fp)

    if not isinstance(raw, dict):
        return fallback, ProfileMeta(name="default", description="profile format invalid; expected object")

    cfg = CoreConfig(
        min_speed_kmh=_read_nested_float(raw, ("telemetry", "speed", "min_active_kmh"), fallback.min_speed_kmh),
        only_show_on_ice=_read_nested_bool(raw, ("telemetry", "surface", "only_show_on_ice"), fallback.only_show_on_ice),
        smoothing_alpha=_read_nested_float(raw, ("telemetry", "smoothing", "alpha"), fallback.smoothing_alpha),
        reset_when_inactive=_read_nested_bool(raw, ("telemetry", "smoothing", "reset_when_inactive"), fallback.reset_when_inactive),
        v2_target_angle_min_deg=_read_nested_float(raw, ("slide", "angle", "target_min_deg"), fallback.v2_target_angle_min_deg),
        v2_target_angle_max_deg=_read_nested_float(raw, ("slide", "angle", "target_max_deg"), fallback.v2_target_angle_max_deg),
        v2_under_slide_angle_deg=_read_nested_float(raw, ("slide", "angle", "under_slide_deg"), fallback.v2_under_slide_angle_deg),
        v2_over_slide_angle_deg=_read_nested_float(raw, ("slide", "angle", "over_slide_deg"), fallback.v2_over_slide_angle_deg),
        v2_max_speed_loss_kmh_per_sec=_read_nested_float(raw, ("slide", "speed", "max_loss_kmh_per_sec"), fallback.v2_max_speed_loss_kmh_per_sec),
        v2_max_oscillation_deg_per_sec=_read_nested_float(raw, ("slide", "stability", "max_oscillation_deg_per_sec"), fallback.v2_max_oscillation_deg_per_sec),
    )

    meta = raw.get("profile", {}) if isinstance(raw.get("profile"), dict) else {}
    return cfg, ProfileMeta(
        name=str(meta.get("name", "default")),
        description=str(meta.get("description", "")),
    )


def find_ghost_files(ghost_dir: str) -> list[str]:
    if not ghost_dir or not os.path.isdir(ghost_dir):
        return []
    files = [
        os.path.join(ghost_dir, name)
        for name in os.listdir(ghost_dir)
        if name.lower().endswith(".ghost.gbx")
    ]
    files.sort(key=lambda p: os.path.basename(p).lower())
    return files


def select_ghost_file(ghost_arg: str, ghost_dir: str) -> str:
    if ghost_arg:
        return os.path.abspath(ghost_arg)

    candidates = find_ghost_files(ghost_dir)
    if not candidates:
        return ""

    if not sys.stdin.isatty():
        return os.path.abspath(candidates[0])

    print("Available ghost files:")
    for i, path in enumerate(candidates, start=1):
        print(f"  {i}. {os.path.basename(path)}")
    print("Select ghost number (Enter for 1): ", end="", flush=True)
    raw = sys.stdin.readline().strip()
    idx = 1
    if raw:
        try:
            idx = int(raw)
        except ValueError:
            idx = 1
    idx = max(1, min(idx, len(candidates)))
    return os.path.abspath(candidates[idx - 1])


def coaching_hint(slide_state: str) -> str:
    if slide_state == "UnderSlide":
        return "MORE ANGLE"
    if slide_state == "OverSlide":
        return "LESS ANGLE"
    if slide_state == "SlideGood":
        return "HOLD"
    if slide_state == "Unstable":
        return "STABILIZE"
    if slide_state == "Entry":
        return "ENTERING"
    if slide_state == "Exit":
        return "EXITING"
    return ""


def render_frame(
    frame_idx: int,
    total_frames: int,
    ghost_frame: GhostFrame,
    frame_output: FrameOutput,
    meter_max_angle_deg: float,
    half_width: int,
    loop_no: int,
    clear: bool,
    angle_history: deque[float],
    efficiency_history: deque[float],
    color: bool,
    view: str,
    profile_name: str,
) -> None:
    clear_screen(clear)
    state = "active" if frame_output.is_active else f"inactive ({frame_output.inactive_reason})"
    state_text = with_color(frame_output.slide_state, state_color_code(frame_output.slide_state), color)
    eff_pct = frame_output.efficiency_score * 100.0

    if view == "compact":
        print("+---------------------------------------------+")
        print("| Ice Slide Assist - Compact Racer View       |")
        print("+---------------------------------------------+")
        print(f" Loop {loop_no} | Frame {frame_idx + 1}/{total_frames} | {state_text} | profile:{profile_name}")
        print(f" Eff {eff_pct:5.1f}% {score_bar(frame_output.efficiency_score, 18)}")
        print(f" Angle {frame_output.smooth_angle_deg:+6.2f} deg | dV {frame_output.smooth_speed_delta_kmh_per_sec:+7.2f} km/h/s")
        print(" " + angle_zone_bar(frame_output.smooth_angle_deg, meter_max_angle_deg, 41))
        print(" " + build_meter_scale_label(meter_max_angle_deg, half_width))
        print(" " + build_meter_bar(frame_output.smooth_angle_deg, meter_max_angle_deg, half_width))
        hint = coaching_hint(frame_output.slide_state)
        if hint:
            print(f" Hint: {hint}")
        print(" Trend Angle: " + build_trend_line(angle_history, -meter_max_angle_deg, meter_max_angle_deg, 32))
        print(" Trend Eff  : " + build_trend_line(efficiency_history, 0.0, 100.0, 32))
    else:
        print("+--------------------------------------------------------------+")
        print("| Ice Slide Assist - Offline Ghost Preview                    |")
        print("+--------------------------------------------------------------+")
        print(f" Loop {loop_no} | Frame {frame_idx + 1}/{total_frames} | Source: .Ghost.gbx synthetic replay | profile:{profile_name}")
        print()
        print(f" State: {state}")
        print(f" V2:    {state_text}   Efficiency {eff_pct:5.1f}% {score_bar(frame_output.efficiency_score)}")
        print(f" Scores: Angle {frame_output.angle_score:4.2f} {score_bar(frame_output.angle_score, 14)}")
        print(f"         Speed {frame_output.speed_score:4.2f} {score_bar(frame_output.speed_score, 14)}")
        print(f"         Stab  {frame_output.stability_score:4.2f} {score_bar(frame_output.stability_score, 14)}")
        print()
        print(f" Angle: raw {ghost_frame.raw_angle_deg:+6.2f} deg | smooth {frame_output.smooth_angle_deg:+6.2f} deg")
        print(" " + angle_zone_bar(frame_output.smooth_angle_deg, meter_max_angle_deg, 49))
        print(" " + build_meter_scale_label(meter_max_angle_deg, half_width))
        print(" " + build_meter_bar(frame_output.smooth_angle_deg, meter_max_angle_deg, half_width))
        print()
        print(f" Speed: {ghost_frame.speed_kmh:6.2f} km/h | dSpeed {frame_output.smooth_speed_delta_kmh_per_sec:+7.2f} km/h/s")
        print(f" Slip:  raw {ghost_frame.lateral_slip:6.3f} | smooth {frame_output.smooth_lateral_slip:6.3f}")
        print(f" Osc:   {frame_output.angle_oscillation_deg_per_sec:6.1f} deg/s | Confidence {frame_output.confidence:5.3f}")
        hint = coaching_hint(frame_output.slide_state)
        if hint:
            print(f" Hint: {hint}")
        print()
        print(" Trend Angle  : " + build_trend_line(angle_history, -meter_max_angle_deg, meter_max_angle_deg, 40))
        print(" Trend Eff(%) : " + build_trend_line(efficiency_history, 0.0, 100.0, 40))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Offline ghost replay preview")
    parser.add_argument("--ghost", default="", help="Path to .Ghost.gbx file")
    parser.add_argument("--ghost-dir", default="ghosts", help="Directory to scan for .Ghost.gbx files")
    parser.add_argument("--config", default="config/ice-slide-profile.json", help="Path to profile JSON config")
    parser.add_argument("--fps", type=float, default=20.0, help="Render FPS")
    parser.add_argument("--playback-speed", type=float, default=1.0, help="Playback speed multiplier")
    parser.add_argument("--loops", type=int, default=1, help="How many full playback loops to run")
    parser.add_argument("--meter-max-angle", type=float, default=45.0, help="Meter max absolute angle")
    parser.add_argument("--min-speed", type=float, default=40.0, help="Min speed gate")
    parser.add_argument("--only-show-on-ice", action="store_true", help="Enable ice-only gate")
    parser.add_argument("--smoothing-alpha", type=float, default=0.20, help="Smoothing alpha")
    parser.add_argument("--v2-target-min", type=float, default=15.0, help="V2 target angle min")
    parser.add_argument("--v2-target-max", type=float, default=30.0, help="V2 target angle max")
    parser.add_argument("--v2-under-angle", type=float, default=10.0, help="V2 under-slide angle")
    parser.add_argument("--v2-over-angle", type=float, default=40.0, help="V2 over-slide angle")
    parser.add_argument("--v2-max-speed-loss", type=float, default=22.0, help="V2 max speed loss km/h/s")
    parser.add_argument("--v2-max-osc", type=float, default=140.0, help="V2 max angle oscillation deg/s")
    parser.add_argument("--view", choices=["compact", "full"], default="full", help="Preview layout mode")
    parser.add_argument("--no-reset-when-inactive", action="store_true", help="Do not decay when inactive")
    parser.add_argument("--no-clear", action="store_true", help="Do not clear terminal per frame")
    parser.add_argument("--no-color", action="store_true", help="Disable ANSI colors")
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    ghost_path = select_ghost_file(args.ghost, os.path.abspath(args.ghost_dir))
    if not ghost_path:
        print(f"No ghost files found in: {os.path.abspath(args.ghost_dir)}", file=sys.stderr)
        return 1
    if not os.path.exists(ghost_path):
        print(f"Ghost file not found: {ghost_path}", file=sys.stderr)
        return 1

    with open(ghost_path, "rb") as fp:
        data = fp.read()

    try:
        frames = derive_ghost_frames(data)
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    base_config = CoreConfig(
        min_speed_kmh=args.min_speed,
        only_show_on_ice=args.only_show_on_ice,
        smoothing_alpha=clamp01(args.smoothing_alpha),
        reset_when_inactive=not args.no_reset_when_inactive,
        v2_target_angle_min_deg=max(0.0, args.v2_target_min),
        v2_target_angle_max_deg=max(0.0, args.v2_target_max),
        v2_under_slide_angle_deg=max(0.0, args.v2_under_angle),
        v2_over_slide_angle_deg=max(0.0, args.v2_over_angle),
        v2_max_speed_loss_kmh_per_sec=max(1.0, args.v2_max_speed_loss),
        v2_max_oscillation_deg_per_sec=max(10.0, args.v2_max_osc),
    )
    config, profile_meta = load_profile(os.path.abspath(args.config), base_config)

    fps = max(1.0, args.fps)
    dt = 1.0 / fps
    playback_speed = max(0.1, args.playback_speed)
    step_dt = 1.0 / 60.0
    half_width = 12
    color_enabled = sys.stdout.isatty() and (not args.no_color)

    smooth_angle = 0.0
    smooth_slip = 0.0
    smooth_speed_delta = 0.0
    prev_speed = 0.0
    prev_raw_angle = 0.0
    idx = 0
    accumulator = 0.0

    loops = max(1, args.loops)
    angle_history: deque[float] = deque(maxlen=120)
    efficiency_history: deque[float] = deque(maxlen=120)
    for loop_no in range(1, loops + 1):
        first_frame = True
        while idx < len(frames):
            sample = frames[idx]
            prev_speed_for_eval = sample.speed_kmh if first_frame else prev_speed
            prev_angle_for_eval = sample.raw_angle_deg if first_frame else prev_raw_angle
            frame_in = FrameInput(
                dt=dt,
                speed_kmh=sample.speed_kmh,
                prev_speed_kmh=prev_speed_for_eval,
                raw_angle_deg=sample.raw_angle_deg,
                prev_raw_angle_deg=prev_angle_for_eval,
                lateral_slip=sample.lateral_slip,
                prev_smooth_angle_deg=smooth_angle,
                prev_smooth_lateral_slip=smooth_slip,
                prev_smooth_speed_delta_kmh_per_sec=smooth_speed_delta,
                is_driving=sample.is_driving,
                is_airborne=sample.is_airborne,
                is_on_ice=sample.is_on_ice,
                has_signal=sample.has_signal,
            )
            frame_out = evaluate_frame(frame_in, config)
            smooth_angle = frame_out.smooth_angle_deg
            smooth_slip = frame_out.smooth_lateral_slip
            smooth_speed_delta = frame_out.smooth_speed_delta_kmh_per_sec
            prev_speed = sample.speed_kmh
            prev_raw_angle = sample.raw_angle_deg
            first_frame = False
            angle_history.append(frame_out.smooth_angle_deg)
            efficiency_history.append(frame_out.efficiency_score * 100.0)

            render_frame(
                frame_idx=idx,
                total_frames=len(frames),
                ghost_frame=sample,
                frame_output=frame_out,
                meter_max_angle_deg=max(1.0, args.meter_max_angle),
                half_width=half_width,
                loop_no=loop_no,
                clear=not args.no_clear,
                angle_history=angle_history,
                efficiency_history=efficiency_history,
                color=color_enabled,
                view=args.view,
                profile_name=profile_meta.name,
            )

            time.sleep(dt)
            accumulator += dt * playback_speed
            while accumulator >= step_dt:
                accumulator -= step_dt
                idx += 1
                if idx >= len(frames):
                    break

        idx = 0
        accumulator = 0.0
        smooth_angle = 0.0
        smooth_slip = 0.0
        smooth_speed_delta = 0.0
        prev_speed = 0.0
        prev_raw_angle = 0.0
        angle_history.clear()
        efficiency_history.clear()

    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
