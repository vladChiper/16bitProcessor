module SignExtend (
    input [8:0] in,
    output [15:0] out
);
    // Extinde bitul de semn (in[8]) pe urmatorii 7 biti pentru a forma 16 biti
    assign out = {{7{in[8]}}, in};
endmodule
