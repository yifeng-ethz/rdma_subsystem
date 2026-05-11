#!/usr/bin/env python3
"""Shared traffic expectations for rdma_subsystem CP evidence builders."""

from __future__ import annotations

import math
import random
from typing import Any

N_CHANNELS = 256
CLOCK_HZ = 125_000_000
HEADER_SYNC_INTERVAL_CYCLES = 910


def snapshot_delta(value: Any) -> int:
    if isinstance(value, dict):
        if "delta" in value:
            return int(value["delta"])
        if "after" in value and "before" in value:
            return int(value["after"]) - int(value["before"])
        if "count" in value:
            return int(value["count"])
    return int(value)


def rate_hz(rate: str | int | float | None) -> float:
    if rate is None:
        return 0.0
    if isinstance(rate, (int, float)):
        return float(rate)
    text = str(rate).upper()
    table = {"R1": 10_000.0, "R2": 100_000.0, "R3": 500_000.0, "R4": 1_000_000.0}
    if text in table:
        return table[text]
    return float(text)


def active_channels(mask: str | None) -> set[int]:
    text = str(mask or "M0").upper()
    all_channels = set(range(N_CHANNELS))
    if text == "M0":
        return all_channels
    if text == "M1":
        return set(range(128, N_CHANNELS))
    if text == "M2":
        return set(range(0, 128))
    if text == "M3":
        return {ch for ch in range(N_CHANNELS) if ch % 2 == 1}
    if text == "M4":
        return {0}
    if text == "M5":
        return all_channels - {0}
    rng = random.Random(1)
    if text == "M6":
        masked = set(rng.sample(range(N_CHANNELS), int(N_CHANNELS * 0.75)))
        return all_channels - masked
    if text == "M7":
        masked = set(rng.sample(range(N_CHANNELS), int(N_CHANNELS * 0.25)))
        return all_channels - masked
    raise SystemExit(f"ERROR: unknown mask {mask}")


def expected_per_channel(mode: str, rate: str | int | float, run_seconds: float) -> float:
    mode = str(mode or "A").upper()
    if mode == "A":
        return float(int(round(float(run_seconds) * rate_hz(rate))))
    if mode == "B":
        cycles = float(run_seconds) * CLOCK_HZ
        return float(int(math.floor(cycles / HEADER_SYNC_INTERVAL_CYCLES) + 1))
    if mode == "C":
        return float(run_seconds) * rate_hz(rate)
    raise SystemExit(f"ERROR: unknown traffic mode {mode}")


def expected_total(mode: str, mask: str, rate: str | int | float, run_seconds: float) -> float:
    return expected_per_channel(mode, rate, run_seconds) * len(active_channels(mask))


def tolerance_for(mode: str, expected: float, configured: float | int | None = None) -> float:
    if configured is not None:
        return float(configured)
    if str(mode or "A").upper() == "C":
        return 5.0 * math.sqrt(max(float(expected), 1.0))
    return 0.0


def get_channel_counts(data: dict[str, Any]) -> list[int] | None:
    for key in (
        "channel_counts",
        "first_stage_channel_counts",
        "emitted_hit_counts",
        "rate_emulator_counts",
        "feb_rate_emulator_counts",
    ):
        raw = data.get(key)
        if raw is None:
            continue
        return normalize_channel_counts(raw)
    return None


def normalize_channel_counts(raw: Any) -> list[int]:
    counts = [0] * N_CHANNELS
    if isinstance(raw, dict):
        for key, value in raw.items():
            ch = int(key)
            if ch < 0 or ch >= N_CHANNELS:
                raise SystemExit(f"ERROR: channel index {ch} outside 0..{N_CHANNELS - 1}")
            counts[ch] = snapshot_delta(value)
        return counts
    if isinstance(raw, list):
        if len(raw) == N_CHANNELS and not any(isinstance(item, dict) for item in raw):
            return [int(value) for value in raw]
        for entry in raw:
            if not isinstance(entry, dict):
                continue
            ch = int(entry.get("channel", entry.get("ch", -1)))
            if ch < 0 or ch >= N_CHANNELS:
                raise SystemExit(f"ERROR: channel entry missing valid channel: {entry}")
            counts[ch] = snapshot_delta(entry)
        return counts
    raise SystemExit("ERROR: unsupported per-channel count format")


def get_first_stage_delta(data: dict[str, Any], channel_counts: list[int] | None = None) -> int | None:
    for key in (
        "feb_rate_emulator_delta",
        "rate_emulator_delta",
        "generator_delta",
        "first_stage_delta",
        "emitted_delta",
    ):
        if key in data:
            return snapshot_delta(data[key])
    block = data.get("feb_rate_emulator") or data.get("rate_emulator") or data.get("generator")
    if isinstance(block, dict):
        for key in ("delta", "count", "emitted", "hits", "after"):
            if key in block:
                return snapshot_delta(block[key])
    if channel_counts is not None:
        return sum(channel_counts)
    return None


def check_expected_channels(
    channel_counts: list[int],
    mode: str,
    mask: str,
    rate: str | int | float,
    run_seconds: float,
    stage: str,
    configured_tolerance: float | int | None = None,
) -> list[dict[str, Any]]:
    expected = expected_per_channel(mode, rate, run_seconds)
    tolerance = tolerance_for(mode, expected, configured_tolerance)
    active = active_channels(mask)
    failures: list[dict[str, Any]] = []
    for ch, observed in enumerate(channel_counts):
        if ch not in active:
            if observed != 0:
                failures.append(
                    {"stage": stage, "channel": ch, "expected": 0, "observed": observed, "tolerance": 0}
                )
                break
            continue
        if abs(float(observed) - expected) > tolerance:
            failures.append(
                {
                    "stage": stage,
                    "channel": ch,
                    "expected": expected,
                    "observed": observed,
                    "tolerance": tolerance,
                }
            )
            break
    return failures

