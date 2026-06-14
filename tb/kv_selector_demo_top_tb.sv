`timescale 1ns/1ps

module kv_selector_demo_top_tb;
    localparam integer DIM = 4;
    localparam integer NUM_BLOCKS = 4;
    localparam integer MAX_K = 2;
    localparam integer ID_WIDTH = 2;

    logic clk = 1'b0;
    logic rst_n = 1'b0;
    logic load_valid = 1'b0;
    logic load_is_query = 1'b0;
    logic [ID_WIDTH-1:0] load_block_id = '0;
    logic [$clog2(DIM)-1:0] load_dimension = '0;
    logic signed [7:0] load_data = '0;
    logic start = 1'b0;
    logic [$clog2(MAX_K+1)-1:0] requested_k = 2;
    logic busy;
    logic done;
    logic [MAX_K*ID_WIDTH-1:0] selected_ids_flat;
    logic [MAX_K*32-1:0] selected_scores_flat;
    logic [$clog2(MAX_K+1)-1:0] selected_count;
    logic [31:0] cycle_count;
    logic [31:0] bytes_read;
    integer query [0:DIM-1];
    integer summaries [0:NUM_BLOCKS-1][0:DIM-1];
    integer block_index;
    integer dimension;

    always #5 clk = ~clk;

    kv_selector_demo_top #(
        .DIM(DIM),
        .NUM_BLOCKS(NUM_BLOCKS),
        .MAX_K(MAX_K)
    ) dut (.*);

    task automatic load_scalar(
        input logic is_query,
        input integer block_id,
        input integer dim_id,
        input integer scalar
    );
        begin
            @(negedge clk);
            load_valid = 1'b1;
            load_is_query = is_query;
            load_block_id = block_id[ID_WIDTH-1:0];
            load_dimension = dim_id[$clog2(DIM)-1:0];
            load_data = scalar[7:0];
            @(negedge clk);
            load_valid = 1'b0;
        end
    endtask

    initial begin
        query[0] = 1; query[1] = 2; query[2] = 3; query[3] = 4;
        summaries[0][0] = 1; summaries[0][1] = 1;
        summaries[0][2] = 1; summaries[0][3] = 1;
        summaries[1][0] = 4; summaries[1][1] = 3;
        summaries[1][2] = 2; summaries[1][3] = 1;
        summaries[2][0] = -1; summaries[2][1] = -2;
        summaries[2][2] = -3; summaries[2][3] = -4;
        summaries[3][0] = 2; summaries[3][1] = 0;
        summaries[3][2] = 2; summaries[3][3] = 0;

        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        for (dimension = 0; dimension < DIM; dimension = dimension + 1)
            load_scalar(1'b1, 0, dimension, query[dimension]);
        for (block_index = 0; block_index < NUM_BLOCKS; block_index = block_index + 1)
            for (dimension = 0; dimension < DIM; dimension = dimension + 1)
                load_scalar(
                    1'b0,
                    block_index,
                    dimension,
                    summaries[block_index][dimension]
                );
        @(negedge clk);
        start = 1'b1;
        @(negedge clk);
        start = 1'b0;

        wait (done);
        #1;
        if (selected_count !== 2)
            $fatal(1, "selected_count=%0d", selected_count);
        if (selected_ids_flat[0 +: ID_WIDTH] !== 1)
            $fatal(1, "rank0 id=%0d", selected_ids_flat[0 +: ID_WIDTH]);
        if (selected_ids_flat[ID_WIDTH +: ID_WIDTH] !== 0)
            $fatal(1, "rank1 id=%0d", selected_ids_flat[ID_WIDTH +: ID_WIDTH]);
        if ($signed(selected_scores_flat[0 +: 32]) !== 20)
            $fatal(1, "rank0 score=%0d", $signed(selected_scores_flat[0 +: 32]));
        if ($signed(selected_scores_flat[32 +: 32]) !== 10)
            $fatal(1, "rank1 score=%0d", $signed(selected_scores_flat[32 +: 32]));
        if (cycle_count !== 21 || bytes_read !== 20)
            $fatal(1, "accounting cycles=%0d bytes=%0d", cycle_count, bytes_read);
        $display(
            "PASS selector ids=1,0 scores=20,10 cycles=%0d bytes=%0d",
            cycle_count,
            bytes_read
        );
        $finish;
    end
endmodule
