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
        repeat (24) @(posedge CLK100MHZ);

        btn[1] = 1'b1;
        repeat (4) @(posedge CLK100MHZ);
        btn[1] = 1'b0;

        wait (led[0]);
        wait (!led[0]);
        @(posedge CLK100MHZ);

        if (dut.completed_operations != 3)
            $fatal(1, "expected three completed operations");
        wait (dut.digital_result_valid);
        if (dut.digital_result_checksum != 144)
            $fatal(
                1,
                "digital matrix checksum mismatch: expected 144, got %0d",
                dut.digital_result_checksum
            );
        if (dut.digital_mac_count != 16 || dut.digital_cycle_count != 16)
            $fatal(1, "digital engine accounting mismatch");
        $display(
            "PASS completed_operations=%0d checksum=%0d macs=%0d cycles=%0d",
            dut.completed_operations,
            dut.digital_result_checksum,
            dut.digital_mac_count,
            dut.digital_cycle_count
        );
        $finish;
    end

    initial begin
        #10000;
        $fatal(1, "testbench timeout");
    end
endmodule
