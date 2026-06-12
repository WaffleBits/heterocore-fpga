module schedule_executor #(
    parameter SCHEDULE_LENGTH = 3,
    parameter SCHEDULE_FILE = "rtl/schedule.hex"
) (
    input  logic        clk,
    input  logic        rst,
    input  logic        start,
    output logic        analog_start,
    output logic        digital_start,
    output logic [15:0] tile_count,
    input  logic        analog_done,
    input  logic        digital_done,
    output logic        busy,
    output logic        done,
    output logic        current_target_analog,
    output logic [15:0] completed_operations
);
    typedef enum logic [2:0] {
        STATE_IDLE,
        STATE_FETCH,
        STATE_DISPATCH,
        STATE_WAIT,
        STATE_FINISH
    } state_t;

    localparam PROGRAM_COUNTER_WIDTH =
        (SCHEDULE_LENGTH <= 1) ? 1 : $clog2(SCHEDULE_LENGTH);

    logic [31:0] schedule [0:SCHEDULE_LENGTH-1];
    logic [31:0] instruction;
    logic [PROGRAM_COUNTER_WIDTH-1:0] program_counter;
    state_t state;

    initial $readmemh(SCHEDULE_FILE, schedule);

    assign busy = (state != STATE_IDLE) && (state != STATE_FINISH);

    always_ff @(posedge clk) begin
        if (rst) begin
            state <= STATE_IDLE;
            program_counter <= '0;
            instruction <= 32'd0;
            analog_start <= 1'b0;
            digital_start <= 1'b0;
            tile_count <= 16'd0;
            done <= 1'b0;
            current_target_analog <= 1'b0;
            completed_operations <= 16'd0;
        end else begin
            analog_start <= 1'b0;
            digital_start <= 1'b0;
            done <= 1'b0;

            case (state)
                STATE_IDLE: begin
                    if (start) begin
                        program_counter <= '0;
                        completed_operations <= 16'd0;
                        state <= STATE_FETCH;
                    end
                end

                STATE_FETCH: begin
                    instruction <= schedule[program_counter];
                    state <= STATE_DISPATCH;
                end

                STATE_DISPATCH: begin
                    current_target_analog <= instruction[31];
                    tile_count <= instruction[15:8] * instruction[7:0];
                    if (instruction[31])
                        analog_start <= 1'b1;
                    else
                        digital_start <= 1'b1;
                    state <= STATE_WAIT;
                end

                STATE_WAIT: begin
                    if ((current_target_analog && analog_done)
                        || (!current_target_analog && digital_done)) begin
                        completed_operations <= completed_operations + 1'b1;
                        if (program_counter == SCHEDULE_LENGTH - 1)
                            state <= STATE_FINISH;
                        else begin
                            program_counter <= program_counter + 1'b1;
                            state <= STATE_FETCH;
                        end
                    end
                end

                STATE_FINISH: begin
                    done <= 1'b1;
                    state <= STATE_IDLE;
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end
endmodule
