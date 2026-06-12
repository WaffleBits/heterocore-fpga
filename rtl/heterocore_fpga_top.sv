module heterocore_fpga_top (
    input  logic       CLK100MHZ,
    input  logic [3:0] btn,
    output logic [3:0] led
);
    logic start_pulse;
    logic analog_start;
    logic digital_start;
    logic [15:0] tile_count;
    logic analog_done;
    logic digital_done;
    logic analog_busy;
    logic digital_busy;
    logic executor_busy;
    logic executor_done;
    logic current_target_analog;
    logic [15:0] completed_operations;
    logic [25:0] heartbeat;

    button_conditioner start_button (
        .clk(CLK100MHZ),
        .rst(btn[0]),
        .asynchronous_button(btn[1]),
        .pressed(start_pulse)
    );

    schedule_executor executor (
        .clk(CLK100MHZ),
        .rst(btn[0]),
        .start(start_pulse),
        .analog_start(analog_start),
        .digital_start(digital_start),
        .tile_count(tile_count),
        .analog_done(analog_done),
        .digital_done(digital_done),
        .busy(executor_busy),
        .done(executor_done),
        .current_target_analog(current_target_analog),
        .completed_operations(completed_operations)
    );

    latency_engine #(
        .BASE_CYCLES(8),
        .CYCLES_PER_TILE(4)
    ) analog_model (
        .clk(CLK100MHZ),
        .rst(btn[0]),
        .start(analog_start),
        .tile_count(tile_count),
        .busy(analog_busy),
        .done(analog_done)
    );

    latency_engine #(
        .BASE_CYCLES(16),
        .CYCLES_PER_TILE(16)
    ) digital_model (
        .clk(CLK100MHZ),
        .rst(btn[0]),
        .start(digital_start),
        .tile_count(tile_count),
        .busy(digital_busy),
        .done(digital_done)
    );

    always_ff @(posedge CLK100MHZ) begin
        if (btn[0])
            heartbeat <= 26'd0;
        else
            heartbeat <= heartbeat + 1'b1;
    end

    assign led[0] = executor_busy;
    assign led[1] = executor_done;
    assign led[2] = current_target_analog;
    assign led[3] = heartbeat[25];
endmodule

