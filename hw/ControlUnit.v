module ControlUnit (
    input clk,
    input reset,
    input [15:0] IR,        // Instruction Register
    input [3:0] Flags,      // Z=0, N=1, C=2, V=3

    // Semnale PC si SP
    output reg PC_Load,
    output reg PC_Inc,
    output reg SP_Push,
    output reg SP_Pop,

    // Semnale de Scriere
    output reg W_IR,
    output reg W_X,
    output reg W_Y,
    output reg W_ACC,
    output reg W_Flags,
    output reg W_Mem,

    // Selectoare Multiplexoare
    output reg [1:0] Sel_MUX_Addr, // 00=PC, 01=SP, 10=SP+1 (pentru RET), 11=SignExt (Adresa Memorie)
    output reg [2:0] Bus_Sel,      // 000=Mem_Out, 001=SignExt, 010=ACC, 011=ALU_Res, 100=X_Out, 101=Y_Out, 110=PC_Out
    output reg Sel_PC_In,          // 0=Branch_Addr (IR[9:0]), 1=Mem_DataOut (pentru RET)
    output reg [5:0] ALU_Op
);

    reg state, next_state;
    parameter FETCH = 1'b0, EXECUTE = 1'b1;

    wire [5:0] opcode = IR[15:10];
    wire reg_bit = IR[9]; // 0=X, 1=Y

    always @(posedge clk or posedge reset) begin
        if (reset) state <= FETCH;
        else state <= next_state;
    end

    always @(*) begin
        // Valori implicite
        PC_Load = 0; PC_Inc = 0; SP_Push = 0; SP_Pop = 0;
        W_IR = 0; W_X = 0; W_Y = 0; W_ACC = 0; W_Flags = 0; W_Mem = 0;
        Sel_MUX_Addr = 2'b00;
        Bus_Sel = 3'b000;
        Sel_PC_In = 1'b0;
        ALU_Op = opcode;
        next_state = FETCH;

        case (state)
            FETCH: begin
                Sel_MUX_Addr = 2'b00; // Adresa Memorie = PC
                W_IR = 1;             // Incarca instructiunea in IR
                PC_Inc = 1;           // PC = PC + 1
                next_state = EXECUTE;
            end

            EXECUTE: begin
                case (opcode[5:4])
                    2'b00: begin // MEMORIE & MOV (0x00 - 0x0F)
                        if (opcode == 6'h00) begin // LDR reg, [addr]
                            Sel_MUX_Addr = 2'b11; // Adresa din SignExt
                            Bus_Sel = 3'b000;     // Datele citite din RAM (Mem_DataOut)
                            if (reg_bit == 1'b0) W_X = 1; else W_Y = 1;
                        end
                        else if (opcode == 6'h01) begin // STR reg, [addr]
                            Sel_MUX_Addr = 2'b11; // Adresa din SignExt
                            Bus_Sel = (reg_bit == 1'b0) ? 3'b100 : 3'b101; // Punem X sau Y pe magistrala
                            W_Mem = 1;            // Scriem in RAM
                        end
                        else if (opcode == 6'h02) begin // MOV reg, imm (Aritmetica/Logica conform PDF)
                            Bus_Sel = 3'b011;     // ALU_Result (ALU face Result = B = SignExt)
                            if (reg_bit == 1'b0) W_X = 1; else W_Y = 1;
                            W_ACC = 1;            // Salvam si in ACC
                            W_Flags = 1;          // MOV este in lista Aritmetica/Logica in PDF, actualizeaza Flags
                        end
                        next_state = FETCH;
                    end

                    2'b01, 2'b10: begin // ARITMETICE & LOGICE (0x10 - 0x28)
                        Bus_Sel = 3'b011; // Punem ALU_Result pe Magistrala
                        W_Flags = 1;      // Actualizam registrul de Flag-uri

                        // CMP (0x17) si TST (0x24) actualizeaza DOAR flag-urile, nu suprascriu registrii
                        if (opcode != 6'h17 && opcode != 6'h24) begin
                            W_ACC = 1; // Salvam rezultatul in Acumulator (ACC)
                            // Actualizam si registrul destinatie (X sau Y) pentru ca operatiile in lant din cod.txt sa functioneze
                            if (reg_bit == 1'b0) W_X = 1; else W_Y = 1;
                        end
                        next_state = FETCH;
                    end

                    2'b11: begin // CONTROL FLOW (0x30 - 0x36)
                        Sel_PC_In = 1'b0; // Implicit salt la Branch_Addr (IR[9:0])
                        if (opcode == 6'h30 && Flags[0] == 1'b1) PC_Load = 1;      // BRZ (Zero)
                        else if (opcode == 6'h31 && Flags[1] == 1'b1) PC_Load = 1; // BRN (Negative)
                        else if (opcode == 6'h32 && Flags[2] == 1'b1) PC_Load = 1; // BRC (Carry)
                        else if (opcode == 6'h33 && Flags[3] == 1'b1) PC_Load = 1; // BRO (Overflow)
                        else if (opcode == 6'h34) PC_Load = 1;                     // BRA (Always)
                        else if (opcode == 6'h35) begin                            // JMP / CALL
                            Sel_MUX_Addr = 2'b01; // Adresa Mem = SP curent
                            Bus_Sel = 3'b110;     // Punem PC_Out (adresa de retur) pe Magistrala
                            W_Mem = 1;            // Scriem PC in stiva la mem[SP]
                            SP_Push = 1;          // SP <= SP - 1
                            Sel_PC_In = 1'b0;     // Incarcam adresa procedurii (IR[9:0])
                            PC_Load = 1;
                        end
                        else if (opcode == 6'h36) begin                            // RET
                            Sel_MUX_Addr = 2'b10; // Citim de la SP + 1 (unde a fost salvat PC-ul la CALL)
                            Sel_PC_In = 1'b1;     // PC primeste Mem_DataOut
                            PC_Load = 1;
                            SP_Pop = 1;           // SP <= SP + 1
                        end
                        next_state = FETCH;
                    end
                endcase
            end
        endcase
    end
endmodule
