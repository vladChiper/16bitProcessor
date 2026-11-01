module ALU (
    input [15:0] A,
    input [15:0] B,
    input [4:0] ALU_Op,
    output reg [15:0] Result,
    output reg [3:0] Flags  // {Overflow(V), Carry(C), Negative(N), Zero(Z)}
);

    // Codificari interne ALU_Op
    parameter OP_ADD = 5'd0,  OP_SUB = 5'd1,
              OP_AND = 5'd2,  OP_OR = 5'd3,   OP_XOR = 5'd4,
              OP_LSR = 5'd5,  OP_LSL = 5'd6,  OP_RSR = 5'd7,
              OP_RSL = 5'd8,  OP_MOV = 5'd9,  OP_MUL = 5'd10,
              OP_DIV = 5'd11, OP_MOD = 5'd12, OP_NOT = 5'd13,
              OP_CMP = 5'd14, OP_TST = 5'd15, OP_INC = 5'd16,
              OP_DEC = 5'd17;

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
            OP_LSR: begin
                Result = A >> shift_amount;
                if (shift_amount != 4'b0) Flags[2] = A[shift_amount - 1'b1];
            end
            OP_LSL: begin
                Result = A << shift_amount;
                if (shift_amount != 4'b0) Flags[2] = A[shift_idx[3:0]];
            end
            OP_RSR: begin
                if (shift_amount == 4'b0) Result = A;
                else begin
                    Result = (A >> shift_amount) | (A << shift_idx[3:0]);
                    Flags[2] = A[shift_amount - 1'b1];
                end
            end
            OP_RSL: begin
                if (shift_amount == 4'b0) Result = A;
                else begin
                    Result = (A << shift_amount) | (A >> shift_idx[3:0]);
                    Flags[2] = A[shift_idx[3:0]];
                end
            end
            OP_MOV: Result = B;
            OP_MUL: begin
                mul_result = {16'b0, A} * {16'b0, B};
                Result = mul_result[15:0];
                Flags[2] = |mul_result[31:16];
            end
            OP_DIV: if (B != 16'b0) Result = A / B;
            OP_MOD: if (B != 16'b0) Result = A % B;
            OP_AND, OP_TST: Result = A & B;
            OP_OR:  Result = A | B;
            OP_XOR: Result = A ^ B;
            OP_NOT: Result = ~A;
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
            default: Result = 16'b0;
        endcase

        Flags[0] = (Result == 16'b0) ? 1'b1 : 1'b0;
        Flags[1] = Result[15];
    end
endmodule
