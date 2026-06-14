`timescale 1ns/1ps

module kv_selector_demo_top #(
    parameter integer DIM = 16,
    parameter integer NUM_BLOCKS = 8,
    parameter integer MAX_K = 4,
    parameter integer DATA_WIDTH = 8,
    parameter integer SCORE_WIDTH = 32,
    parameter integer ID_WIDTH = (NUM_BLOCKS <= 2) ? 1 : $clog2(NUM_BLOCKS)
) (
    input  logic                                      clk,
    input  logic                                      rst_n,
    input  logic                                      load_valid,
    input  logic                                      load_is_query,
    input  logic [ID_WIDTH-1:0]                       load_block_id,
    input  logic [$clog2(DIM)-1:0]                    load_dimension,
    input  logic signed [DATA_WIDTH-1:0]              load_data,
    input  logic                                      start,
    input  logic [$clog2(MAX_K+1)-1:0]                requested_k,
    output logic                                      busy,
    output logic                                      done,
    output logic [MAX_K*ID_WIDTH-1:0]                 selected_ids_flat,
    output logic [MAX_K*SCORE_WIDTH-1:0]              selected_scores_flat,
    output logic [$clog2(MAX_K+1)-1:0]                selected_count,
    output logic [31:0]                               cycle_count,
    output logic [31:0]                               bytes_read
);
    logic [DIM*DATA_WIDTH-1:0] query_flat;
    logic [NUM_BLOCKS*DIM*DATA_WIDTH-1:0] summaries_flat;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            query_flat <= '0;
            summaries_flat <= '0;
        end else if (load_valid && !busy) begin
            if (load_is_query)
                query_flat[load_dimension*DATA_WIDTH +: DATA_WIDTH] <= load_data;
            else
                summaries_flat[
                    ((load_block_id*DIM + load_dimension)*DATA_WIDTH) +: DATA_WIDTH
                ] <= load_data;
        end
    end

    kv_block_selector #(
        .DIM(DIM),
        .NUM_BLOCKS(NUM_BLOCKS),
        .MAX_K(MAX_K),
        .DATA_WIDTH(DATA_WIDTH),
        .SCORE_WIDTH(SCORE_WIDTH),
        .ID_WIDTH(ID_WIDTH)
    ) selector (.*);
endmodule
