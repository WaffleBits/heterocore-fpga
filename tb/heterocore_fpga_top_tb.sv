`timescale 1ns/1ps

module heterocore_fpga_top_tb;
    logic CLK100MHZ = 1'b0;
    logic [3:0] btn = 4'b0000;
    logic [3:0] led;

    always #5 CLK100MHZ = ~CLK100MHZ;

    heterocore_fpga_top dut (.*);

    initial begin
        btn[0] = 1'b1;
        repeat (4) @(posedge CLK100MHZ);
        btn[0] = 1'b0;
        repeat (4) @(posedge CLK100MHZ);

        btn[1] = 1'b1;
        repeat (4) @(posedge CLK100MHZ);
        btn[1] = 1'b0;

        wait (led[0]);
        wait (!led[0]);
        @(posedge CLK100MHZ);

        if (dut.completed_operations != 3)
            $fatal(1, "expected three completed operations");
        $display(
            "PASS completed_operations=%0d heartbeat=%0b",
            dut.completed_operations,
            led[3]
        );
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "testbench timeout");
    end
endmodule

