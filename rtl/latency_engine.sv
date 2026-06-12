module latency_engine #(
    parameter BASE_CYCLES = 4,
    parameter CYCLES_PER_TILE = 2
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    input  logic [15:0] tile_count,
    output logic        busy,
    output logic        done
);
    logic [31:0] remaining;
    logic [31:0] requested_cycles;

    always_comb begin
        requested_cycles = BASE_CYCLES + tile_count * CYCLES_PER_TILE;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            remaining <= 32'd0;
            busy <= 1'b0;
            done <= 1'b0;
        end else begin
            done <= 1'b0;
            if (start && !busy) begin
                remaining <= requested_cycles;
                busy <= 1'b1;
            end else if (busy && remaining > 1) begin
                remaining <= remaining - 1'b1;
            end else if (busy) begin
                remaining <= 32'd0;
                busy <= 1'b0;
                done <= 1'b1;
            end
        end
    end
endmodule

