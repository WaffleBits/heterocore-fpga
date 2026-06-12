module button_conditioner (
    input  logic clk,
    input  logic rst,
    input  logic asynchronous_button,
    output logic pressed
);
    logic sync_0;
    logic sync_1;
    logic previous;

    always_ff @(posedge clk) begin
        if (rst) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
            previous <= 1'b0;
            pressed <= 1'b0;
        end else begin
            sync_0 <= asynchronous_button;
            sync_1 <= sync_0;
            previous <= sync_1;
            pressed <= sync_1 && !previous;
        end
    end
endmodule

