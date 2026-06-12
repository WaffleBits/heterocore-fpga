import importlib.util
import unittest
from pathlib import Path

MODULE_PATH = Path(__file__).parents[1] / "tools" / "build_schedule.py"
SPEC = importlib.util.spec_from_file_location("build_schedule", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class ScheduleTests(unittest.TestCase):
    def test_checked_in_schedule_matches_sample(self):
        root = Path(__file__).parents[1]
        import json

        plan = json.loads((root / "examples" / "sample.plan.json").read_text())
        expected = [f"{MODULE.encode(op):08x}" for op in plan["operators"]]
        actual = [
            line
            for line in (root / "rtl" / "schedule.hex").read_text().splitlines()
            if line
        ]
        self.assertEqual(actual, expected)


if __name__ == "__main__":
    unittest.main()
