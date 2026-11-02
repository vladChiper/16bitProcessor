module StackPointer (
    input clk,
    input reset,
    input push, // Semnal venit din Unitatea de Control
    input pop,  // Semnal venit din Unitatea de Control
    output reg [15:0] sp_out
);

    always @(posedge clk or posedge reset) begin
        if (reset)
            // Stiva creste invers, deci porneste de la adresa maxima
            sp_out <= 16'hFFFF;
        else if (push)
            // Scadem adresa pentru a aloca spatiu
            sp_out <= sp_out - 16'd1;
        else if (pop)
            // Crestem adresa pentru a elibera spatiul
            sp_out <= sp_out + 16'd1;
    end

endmodule
