module Datapath (
    input clk,
    input reset
);

    // Magistrale si Fire Interne
    wire [15:0] Magistrala;
    wire [15:0] Mem_DataOut, SignExt_Out, ALU_Result, ACC_Out, X_Out, Y_Out, PC_Out, SP_Out, IR_Out;
    wire [15:0] Mux_Addr_Out, Mux_X_Out, Mux_Y_Out;
    wire [3:0]  Flags_Out, Flags_Reg_Out;
    wire [4:0]  ALU_Op;
    
    // Semnale ControlUnit
    wire PC_Load, PC_Inc, SP_Push, SP_Pop;
    wire W_IR, W_X, W_Y, W_ACC, W_Flags, W_Mem;
    wire [1:0] Sel_MUX_Addr, Bus_Sel;
    wire Sel_MUX_X, Sel_MUX_Y;

    // MAGISTRALA COMUNA (Multiplexor Principal)
    assign Magistrala = (Bus_Sel == 2'b00) ? Mem_DataOut :
                        (Bus_Sel == 2'b01) ? SignExt_Out :
                        (Bus_Sel == 2'b10) ? ACC_Out :
                        (Bus_Sel == 2'b11) ? ALU_Result : 16'b0;

    // MULTIPLEXOARE 
    assign Mux_Addr_Out = (Sel_MUX_Addr == 2'b00) ? PC_Out :
                          (Sel_MUX_Addr == 2'b01) ? SP_Out : SignExt_Out;
                          
    assign Mux_X_Out = (Sel_MUX_X) ? Magistrala : X_Out;
    assign Mux_Y_Out = (Sel_MUX_Y) ? Magistrala : Y_Out;

    // INSTANTIERE MODULE
    ControlUnit CU (
        .clk(clk), .reset(reset), .IR(IR_Out), .Flags(Flags_Reg_Out),
        .PC_Load(PC_Load), .PC_Inc(PC_Inc), .SP_Push(SP_Push), .SP_Pop(SP_Pop),
        .W_IR(W_IR), .W_X(W_X), .W_Y(W_Y), .W_ACC(W_ACC), .W_Flags(W_Flags), .W_Mem(W_Mem),
        .Sel_MUX_Addr(Sel_MUX_Addr), .Bus_Sel(Bus_Sel), 
        .Sel_MUX_X(Sel_MUX_X), .Sel_MUX_Y(Sel_MUX_Y), .ALU_Op(ALU_Op)
    );

    ProgramCounter PC (
        .clk(clk), .reset(reset), .load(PC_Load), .increment(PC_Inc), 
        .addr_in(SignExt_Out), .pc_out(PC_Out)
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
        .A(Mux_X_Out), .B(Mux_Y_Out), .ALU_Op(ALU_Op), .Result(ALU_Result), .Flags(Flags_Out)
    );

    // REGISTRI (Folosim acelasi modul generic generat in prealabil)
    Register_16bit REG_IR  (.clk(clk), .reset(reset), .write_enable(W_IR), .data_in(Mem_DataOut), .data_out(IR_Out));
    Register_16bit REG_X   (.clk(clk), .reset(reset), .write_enable(W_X),  .data_in(Magistrala), .data_out(X_Out));
    Register_16bit REG_Y   (.clk(clk), .reset(reset), .write_enable(W_Y),  .data_in(Magistrala), .data_out(Y_Out));
    Register_16bit REG_ACC (.clk(clk), .reset(reset), .write_enable(W_ACC),.data_in(ALU_Result), .data_out(ACC_Out));
    
    // Registrul de Flag-uri pe 4 biti
    reg [3:0] flag_reg;
    always @(posedge clk or posedge reset) begin
        if (reset) flag_reg <= 4'b0;
        else if (W_Flags) flag_reg <= Flags_Out;
    end
    assign Flags_Reg_Out = flag_reg;

endmodule
