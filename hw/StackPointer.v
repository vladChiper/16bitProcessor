module StackPointer (
    input clk,
    input reset,
    input push,
    input pop,
    output reg [15:0] sp_out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            sp_out <= 16'hFFFF;
        else if (push)
            sp_out <= sp_out - 16'd1;
        else if (pop)
            sp_out <= sp_out + 16'd1;
    end
endmodule
