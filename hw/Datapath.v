module Datapath (
    input clk,
    input reset
);

    // Magistrale si Fire Interne
    wire [15:0] Magistrala;
    wire [15:0] Mem_DataOut, SignExt_Out, ALU_Result, ACC_Out, X_Out, Y_Out, PC_Out, SP_Out, IR_Out;
    wire [15:0] Mux_Addr_Out, ALU_In_A, ALU_In_B, PC_In;
    wire [3:0]  Flags_Out, Flags_Reg_Out;
    wire [5:0]  ALU_Op;

    // Semnale ControlUnit
    wire PC_Load, PC_Inc, SP_Push, SP_Pop;
    wire W_IR, W_X, W_Y, W_ACC, W_Flags, W_Mem;
    wire [1:0] Sel_MUX_Addr;
    wire [2:0] Bus_Sel;
    wire Sel_PC_In;

    // Extensie zero pe 16 biti pentru adresele de salt de 10 biti (IR[9:0])
    wire [15:0] Branch_Addr = {6'b0, IR_Out[9:0]};

    // Selectie intrare PC (Adresa salt din instructiune sau adresa de retur din stiva pentru RET)
    assign PC_In = (Sel_PC_In) ? Mem_DataOut : Branch_Addr;

    // MAGISTRALA COMUNA (Multiplexor Principal)
    assign Magistrala = (Bus_Sel == 3'b000) ? Mem_DataOut :
                        (Bus_Sel == 3'b001) ? SignExt_Out :
                        (Bus_Sel == 3'b010) ? ACC_Out :
                        (Bus_Sel == 3'b011) ? ALU_Result :
                        (Bus_Sel == 3'b100) ? X_Out :
                        (Bus_Sel == 3'b101) ? Y_Out :
                        (Bus_Sel == 3'b110) ? PC_Out : 16'b0;

    // MULTIPLEXOR ADRESA MEMORIE
    // 00 = PC_Out (Fetch), 01 = SP_Out (Push/Call), 10 = SP_Out + 1 (Pop/Ret), 11 = SignExt_Out (LDR/STR)
    assign Mux_Addr_Out = (Sel_MUX_Addr == 2'b00) ? PC_Out :
                          (Sel_MUX_Addr == 2'b01) ? SP_Out :
                          (Sel_MUX_Addr == 2'b10) ? (SP_Out + 16'd1) : SignExt_Out;

    // INTRARI ALU:
    // A primeste valoarea registrului selectat de bitul IR[9] (0 -> X_Out, 1 -> Y_Out)
    // B primeste valoarea imediata extinsa cu semn (SignExt_Out)
    assign ALU_In_A = (IR_Out[9] == 1'b0) ? X_Out : Y_Out;
    assign ALU_In_B = SignExt_Out;

    // INSTANTIERE MODULE
    ControlUnit CU (
        .clk(clk), .reset(reset), .IR(IR_Out), .Flags(Flags_Reg_Out),
        .PC_Load(PC_Load), .PC_Inc(PC_Inc), .SP_Push(SP_Push), .SP_Pop(SP_Pop),
        .W_IR(W_IR), .W_X(W_X), .W_Y(W_Y), .W_ACC(W_ACC), .W_Flags(W_Flags), .W_Mem(W_Mem),
        .Sel_MUX_Addr(Sel_MUX_Addr), .Bus_Sel(Bus_Sel),
        .Sel_PC_In(Sel_PC_In), .ALU_Op(ALU_Op)
    );

    ProgramCounter PC (
        .clk(clk), .reset(reset), .load(PC_Load), .increment(PC_Inc),
        .addr_in(PC_In), .pc_out(PC_Out)
    );

    StackPointer SP (
        .clk(clk), .reset(reset), .push(SP_Push), .pop(SP_Pop), .sp_out(SP_Out)
    );

    Memory MEM (
        .clk(clk), .we(W_Mem), .addr(Mux_Addr_Out), .data_in(Magistrala), .data_out(Mem_DataOut)
    );

    SignExtend SE (
        .in(IR_Out[8:0]), .out(SignExt_Out)
    );

    ALU ALU_Inst (
        .A(ALU_In_A), .B(ALU_In_B), .ALU_Op(ALU_Op), .Result(ALU_Result), .Flags(Flags_Out)
    );

    // REGISTRI
    Register_16bit REG_IR  (.clk(clk), .reset(reset), .write_enable(W_IR),  .data_in(Mem_DataOut), .data_out(IR_Out));
    Register_16bit REG_X   (.clk(clk), .reset(reset), .write_enable(W_X),   .data_in(Magistrala),  .data_out(X_Out));
    Register_16bit REG_Y   (.clk(clk), .reset(reset), .write_enable(W_Y),   .data_in(Magistrala),  .data_out(Y_Out));
    Register_16bit REG_ACC (.clk(clk), .reset(reset), .write_enable(W_ACC), .data_in(ALU_Result),  .data_out(ACC_Out));

    // Registrul de Flag-uri pe 4 biti
    reg [3:0] flag_reg;
    always @(posedge clk or posedge reset) begin
        if (reset) flag_reg <= 4'b0;
        else if (W_Flags) flag_reg <= Flags_Out;
    end
    assign Flags_Reg_Out = flag_reg;

endmodule
