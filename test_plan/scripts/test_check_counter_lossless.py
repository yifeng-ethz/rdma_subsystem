#!/usr/bin/env python3
"""Regression tests for strict counter-chain traffic evidence."""

from __future__ import annotations

import unittest

from check_counter_lossless import STAGES, check_conservation


class CounterLosslessTests(unittest.TestCase):
    def test_zero_traffic_with_programmed_rate_fails_at_c1(self) -> None:
        data = {
            "schema_version": 1,
            "cohort": "SYN",
            "matrix_id": "SYN_A_M4_R1",
            "mode": "A",
            "mask": "M4",
            "rate": "R1",
            "run_seconds": 30,
            "feb_rate_emulator_delta": 0,
            "channel_counts": [0] * 256,
            "stage_counts": {stage: 0 for stage in STAGES},
            "bar1": {
                "CNT_OPQ_INPUT_W": 0,
                "CNT_BYTES_WRITTEN": 0,
                "CNT_RQE_CONSUMED": 0,
                "CNT_CQE_POSTED": 0,
                "CNT_HALT": 0,
                "EVENT_SKIP_EVENT_DMA_R": 0,
            },
        }

        result = check_conservation(data)

        self.assertEqual(result["status"], "FAIL_AT_C1")
        self.assertIn("zero FEB-side delta", result["detail"])


if __name__ == "__main__":
    unittest.main()

