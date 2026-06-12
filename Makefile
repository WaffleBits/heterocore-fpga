RTL := rtl/button_conditioner.sv rtl/latency_engine.sv rtl/int8_matmul_engine.sv rtl/schedule_executor.sv rtl/heterocore_fpga_top.sv
PYTHON ?= python3

.PHONY: test schedule synth vivado clean

test:
	mkdir -p build
	$(PYTHON) tools/build_schedule.py examples/sample.plan.json -o rtl/schedule.hex
	$(PYTHON) -m unittest discover -s tests
	iverilog -g2012 -s heterocore_fpga_top_tb -o build/heterocore_fpga_top_tb $(RTL) tb/heterocore_fpga_top_tb.sv
	vvp build/heterocore_fpga_top_tb

schedule:
	$(PYTHON) tools/build_schedule.py examples/sample.plan.json -o rtl/schedule.hex

synth:
	mkdir -p build
	yosys -l build/yosys.log scripts/synth.ys

vivado:
	vivado -mode batch -source scripts/build_vivado.tcl

clean:
	rm -rf build obj_dir
