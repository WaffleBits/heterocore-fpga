# HeteroCore FPGA

[![CI](https://github.com/WaffleBits/heterocore-fpga/actions/workflows/ci.yml/badge.svg)](https://github.com/WaffleBits/heterocore-fpga/actions/workflows/ci.yml)

FPGA implementation shell for HeteroCore schedules. It loads compiler-generated
instructions into initialized memory, dispatches analog and digital operations,
and exposes status on a Digilent Arty A7-35T.

> CI simulation and synthesis are not board measurements. Throughput, power,
> and timing must be measured after programming a physical FPGA.

## Verify Without Hardware

```bash
sudo apt-get install iverilog yosys make
make test
make synth
```

The self-checking simulation executes a three-operation mixed schedule. Its
digital operation runs a real 2x4 by 4x2 signed INT8 matrix multiplication,
checks the output checksum (`144`), and verifies 16 MACs in 16 compute cycles.
Yosys then synthesizes the board top for the Xilinx 7-series architecture and
records the resource report as a CI artifact.

The checked-in design currently synthesizes with Yosys 0.33 to 954 primitive
cells, including 459 flip-flops and two DSP48E1 blocks. This is an open-source
synthesis result for the fixed demonstration kernel, not a Vivado post-route
utilization or timing result.

The repository now also includes a host-loadable KV selector demo. A host
streams one quantized query and multiple key-block summaries, starts the
datapath, and receives deterministic top-k block IDs, scores, cycle count, and
logical bytes read. The self-checking simulation returns IDs `1,0`, scores
`20,10`, 21 cycles, and 20 bytes for the fixed fixture.

`make synth-selector` runs Yosys 0.33 on the default 16-dimension, eight-block,
top-4 core. The checked summary reports 12,341 generic cells after technology
mapping, including the host-load register storage. This is an open-source
generic synthesis count, not Xilinx utilization, placement, timing, or power.

## Build a Schedule

```bash
python tools/build_schedule.py examples/sample.plan.json \
  -o rtl/schedule.hex
```

The instruction format matches `heterocore-rtl`: target, opcode, and M/K/N tile
counts packed into 32 bits.

`results/tiny_char_transformer_schedule.hex` contains the full 27-operation
ONNX model schedule. The current board demo executes the smaller three-command
fixture while the host-loading interface remains future work.

## Build for Arty A7-35T

With Vivado on `PATH`:

```bash
make vivado
```

The batch flow synthesizes, places, routes, writes utilization and timing
reports, creates a checkpoint, and emits a bitstream under `build/vivado`.

See [ARCHITECTURE.md](ARCHITECTURE.md) for button and LED behavior.

## Current Hardware Boundary

The analog target remains a deterministic latency model. The digital target is
now a synthesizable INT8 matrix engine with local activation, weight, and
result storage. It is still a fixed demonstration kernel rather than a complete
transformer datapath. The next physical milestone is loading compiler-generated
tiles over a host interface and measuring latency and wall power on a board.

The standalone `kv_selector_demo_top` closes the host-load interface and
selector-datapath milestone in simulation. Physical timing, utilization,
bitstream, power, and parity evidence remain blocked on a connected board and
Vivado board build.
