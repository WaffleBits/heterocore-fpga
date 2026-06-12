import argparse
import json
from math import ceil
from pathlib import Path

OPCODES = {
    "embedding": 0,
    "linear": 1,
    "matmul": 2,
    "softmax": 3,
    "layer_norm": 4,
    "gelu": 5,
}


def encode(operator: dict, array_size: int = 128) -> int:
    dimensions = operator["dimensions"]
    target = 1 if operator["target"] == "analog" else 0
    opcode = OPCODES.get(operator["type"], 15)
    m_tiles = min(0x7FF, ceil(dimensions["m"] / array_size))
    k_tiles = min(0xFF, ceil(dimensions["k"] / array_size))
    n_tiles = min(0xFF, ceil(dimensions["n"] / array_size))
    return (target << 31) | (opcode << 27) | (m_tiles << 16) | (k_tiles << 8) | n_tiles


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("plan", type=Path)
    parser.add_argument("-o", "--output", type=Path, default=Path("rtl/schedule.hex"))
    args = parser.parse_args()
    plan = json.loads(args.plan.read_text(encoding="utf-8"))
    words = [encode(operator) for operator in plan["operators"]]
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(
        "\n".join(f"{word:08x}" for word in words) + "\n",
        encoding="ascii",
    )
    print(f"wrote {len(words)} schedule words")


if __name__ == "__main__":
    main()

