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

The self-checking simulation executes a three-operation mixed schedule. Yosys
then synthesizes the board top for the Xilinx 7-series architecture and records
the resource report as a CI artifact.

The checked-in design currently synthesizes with Yosys 0.33 to an estimated
109 logic cells, 125 flip-flops, and one DSP48E1. This is an open-source
synthesis estimate for the placeholder latency-model shell, not a Vivado
post-route utilization or timing result.

## Build a Schedule

```bash
python tools/build_schedule.py examples/sample.plan.json \
  -o rtl/schedule.hex
```

The instruction format matches `heterocore-rtl`: target, opcode, and M/K/N tile
counts packed into 32 bits.

## Build for Arty A7-35T

With Vivado on `PATH`:

```bash
make vivado
```

The batch flow synthesizes, places, routes, writes utilization and timing
reports, creates a checkpoint, and emits a bitstream under `build/vivado`.

See [ARCHITECTURE.md](ARCHITECTURE.md) for button and LED behavior.

## Current Hardware Boundary

The analog and digital compute engines are deterministic latency models. They
verify schedule execution but do not implement a neural network datapath or
represent measured analog hardware. The next physical milestone is replacing
one latency model with a real accelerator or external array interface.
