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
    logic engine_initialized;
    logic [4:0] initialization_index;
    logic activation_write_enable;
    logic [2:0] activation_write_address;
    logic signed [7:0] activation_write_data;
    logic weight_write_enable;
    logic [2:0] weight_write_address;
    logic signed [7:0] weight_write_data;
    logic [1:0] result_read_address;
    logic signed [31:0] result_read_data;
    logic [31:0] digital_mac_count;
    logic [31:0] digital_cycle_count;
    logic result_collecting;
    logic signed [31:0] digital_result_checksum;
    logic digital_result_valid;
    logic executor_busy;
    logic executor_done;
    logic current_target_analog;
    logic [15:0] completed_operations;
    logic [25:0] heartbeat;

    function automatic logic signed [7:0] activation_value(
        input logic [2:0] address
    );
        case (address)
            3'd0: activation_value = 8'sd1;
            3'd1: activation_value = 8'sd2;
            3'd2: activation_value = 8'sd3;
            3'd3: activation_value = 8'sd4;
            3'd4: activation_value = -8'sd1;
            3'd5: activation_value = 8'sd0;
            3'd6: activation_value = 8'sd2;
            default: activation_value = 8'sd1;
        endcase
    endfunction

    function automatic logic signed [7:0] weight_value(
        input logic [2:0] address
    );
        case (address)
            3'd0: weight_value = 8'sd1;
            3'd1: weight_value = 8'sd2;
            3'd2: weight_value = 8'sd3;
            3'd3: weight_value = 8'sd4;
            3'd4: weight_value = 8'sd5;
            3'd5: weight_value = 8'sd6;
            3'd6: weight_value = 8'sd7;
            default: weight_value = 8'sd8;
        endcase
    endfunction

    assign activation_write_enable = !engine_initialized
        && initialization_index < 8;
    assign activation_write_address = initialization_index[2:0];
    assign activation_write_data = activation_value(initialization_index[2:0]);
    assign weight_write_enable = !engine_initialized
        && initialization_index >= 8
        && initialization_index < 16;
    assign weight_write_address = initialization_index[2:0];
    assign weight_write_data = weight_value(initialization_index[2:0]);

    button_conditioner start_button (
        .clk(CLK100MHZ),
        .rst(btn[0]),
        .asynchronous_button(btn[1]),
        .pressed(start_pulse)
    );

    schedule_executor executor (
        .clk(CLK100MHZ),
        .rst(btn[0]),
        .start(start_pulse && engine_initialized),
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

    int8_matmul_engine digital_engine (
        .clk(CLK100MHZ),
        .rst_n(!btn[0]),
        .start(digital_start),
        .activation_write_enable(activation_write_enable),
        .activation_write_address(activation_write_address),
        .activation_write_data(activation_write_data),
        .weight_write_enable(weight_write_enable),
        .weight_write_address(weight_write_address),
        .weight_write_data(weight_write_data),
        .result_read_address(result_read_address),
        .result_read_data(result_read_data),
        .busy(digital_busy),
        .done(digital_done),
        .mac_count(digital_mac_count),
        .cycle_count(digital_cycle_count)
    );

    always_ff @(posedge CLK100MHZ) begin
        if (btn[0]) begin
            heartbeat <= 26'd0;
            initialization_index <= 5'd0;
            engine_initialized <= 1'b0;
            result_read_address <= 2'd0;
            result_collecting <= 1'b0;
            digital_result_checksum <= 32'sd0;
            digital_result_valid <= 1'b0;
        end else begin
            heartbeat <= heartbeat + 1'b1;
            if (!engine_initialized) begin
                if (initialization_index == 16)
                    engine_initialized <= 1'b1;
                else
                    initialization_index <= initialization_index + 1'b1;
            end
            if (digital_done) begin
                result_read_address <= 2'd0;
                result_collecting <= 1'b1;
                digital_result_checksum <= 32'sd0;
                digital_result_valid <= 1'b0;
            end else if (result_collecting) begin
                digital_result_checksum <= digital_result_checksum + result_read_data;
                if (result_read_address == 3) begin
                    result_collecting <= 1'b0;
                    digital_result_valid <= 1'b1;
                end else begin
                    result_read_address <= result_read_address + 1'b1;
                end
            end
        end
    end

    assign led[0] = executor_busy;
    assign led[1] = executor_done;
    assign led[2] = current_target_analog;
    assign led[3] = heartbeat[25];
endmodule
