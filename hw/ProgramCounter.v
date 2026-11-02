module ProgramCounter (
    input clk,
    input reset,
    input load,          // Semnal pentru salturi (Branch/Jump/Call)
    input increment,     // Semnal pentru a trece la urmatoarea instructiune
    input [15:0] addr_in,
    output reg [15:0] pc_out
);
    always @(posedge clk or posedge reset) begin
        if (reset)
            pc_out <= 16'b0;
        else if (load)
            pc_out <= addr_in;
        else if (increment)
            pc_out <= pc_out + 16'd1;
    end
endmodule
