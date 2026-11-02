module ALU (
    input [15:0] A,          // Operandul 1 (valoarea registrului selectat X sau Y)
    input [15:0] B,          // Operandul 2 (valoarea imediata extinsa la 16 biti)
    input [5:0] ALU_Op,      // Opcode-ul de 6 biti direct din IR[15:10]
    output reg [15:0] Result,
    output reg [3:0] Flags   // {Overflow(V)=Flags[3], Carry(C)=Flags[2], Negative(N)=Flags[1], Zero(Z)=Flags[0]}
);

    // Codificari aliniate 1-la-1 cu assembler.c
    parameter OP_MOV = 6'h02,
              OP_ADD = 6'h10, OP_SUB = 6'h11, OP_MUL = 6'h12,
              OP_DIV = 6'h13, OP_MOD = 6'h14, OP_INC = 6'h15,
              OP_DEC = 6'h16, OP_CMP = 6'h17,
              OP_AND = 6'h20, OP_OR  = 6'h21, OP_XOR = 6'h22,
              OP_NOT = 6'h23, OP_TST = 6'h24, OP_LSL = 6'h25,
              OP_LSR = 6'h26, OP_RSL = 6'h27, OP_RSR = 6'h28;

    reg [16:0] temp_result;
    reg [31:0] mul_result;
    reg [3:0] shift_amount;

    // Extindere pe 5 biti pentru a preveni out-of-bounds cand shift_amount este 0
    wire [4:0] shift_idx;
    assign shift_idx = 5'd16 - {1'b0, B[3:0]};

    always @(*) begin
        Result = 16'b0;
        temp_result = 17'b0;
        mul_result = 32'b0;
        shift_amount = B[3:0];
        Flags = 4'b0;

        case(ALU_Op)
            OP_MOV: begin
                Result = B;
            end
            OP_ADD: begin
                temp_result = {1'b0, A} + {1'b0, B};
                Result = temp_result[15:0];
                Flags[2] = temp_result[16];
                Flags[3] = (~A[15] & ~B[15] & Result[15]) | (A[15] & B[15] & ~Result[15]);
            end
            OP_SUB, OP_CMP: begin
                temp_result = {1'b0, A} - {1'b0, B};
                Result = temp_result[15:0];
                Flags[2] = temp_result[16];
                Flags[3] = (~A[15] & B[15] & Result[15]) | (A[15] & ~B[15] & ~Result[15]);
            end
            OP_MUL: begin
                mul_result = {16'b0, A} * {16'b0, B};
                Result = mul_result[15:0];
                Flags[2] = |mul_result[31:16];
            end
            OP_DIV: begin
                if (B != 16'b0) Result = A / B;
            end
            OP_MOD: begin
                if (B != 16'b0) Result = A % B;
            end
            OP_INC: begin
                temp_result = {1'b0, A} + 17'd1;
                Result = temp_result[15:0];
                Flags[2] = temp_result[16];
                Flags[3] = ~A[15] & Result[15];
            end
            OP_DEC: begin
                temp_result = {1'b0, A} - 17'd1;
                Result = temp_result[15:0];
                Flags[2] = temp_result[16];
                Flags[3] = A[15] & ~Result[15];
            end
            OP_AND, OP_TST: begin
                Result = A & B;
            end
            OP_OR: begin
                Result = A | B;
            end
            OP_XOR: begin
                Result = A ^ B;
            end
            OP_NOT: begin
                Result = ~A;
            end
            OP_LSL: begin
                Result = A << shift_amount;
                if (shift_amount != 4'b0) Flags[2] = A[shift_idx[3:0]];
            end
            OP_LSR: begin
                Result = A >> shift_amount;
                if (shift_amount != 4'b0) Flags[2] = A[shift_amount - 1'b1];
            end
            OP_RSL: begin
                if (shift_amount == 4'b0) Result = A;
                else begin
                    Result = (A << shift_amount) | (A >> shift_idx[3:0]);
                    Flags[2] = A[shift_idx[3:0]];
                end
            end
            OP_RSR: begin
                if (shift_amount == 4'b0) Result = A;
                else begin
                    Result = (A >> shift_amount) | (A << shift_idx[3:0]);
                    Flags[2] = A[shift_amount - 1'b1];
                end
            end
            default: Result = 16'b0;
        endcase

        Flags[0] = (Result == 16'b0) ? 1'b1 : 1'b0; // Zero (Z)
        Flags[1] = Result[15];                      // Negative (N)
    end
endmodule
