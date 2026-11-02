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
    output reg [1:0] Sel_MUX_Addr, // 00=PC, 01=SP, 10=Magistrala(Adresa Imediata)
    output reg [1:0] Bus_Sel,      // 00=Mem_Out, 01=SignExt, 10=ACC, 11=ALU_Res
    output reg Sel_MUX_X,          // 0=Reg_X, 1=Magistrala
    output reg Sel_MUX_Y,          // 0=Reg_Y, 1=Magistrala
    output reg [4:0] ALU_Op
);

    reg state, next_state;
    parameter FETCH = 1'b0, EXECUTE = 1'b1;

    // Extragere campuri din Instructiune
    wire [5:0] opcode = IR[15:10];
    wire reg_bit = IR[9]; // 0=X, 1=Y

    // Registru de Stare
    always @(posedge clk or posedge reset) begin
        if (reset) state <= FETCH;
        else state <= next_state;
    end

    // Logica combinationala FSM
    always @(*) begin
        // Valori implicite (evitam latch-uri)
        PC_Load = 0; PC_Inc = 0; SP_Push = 0; SP_Pop = 0;
        W_IR = 0; W_X = 0; W_Y = 0; W_ACC = 0; W_Flags = 0; W_Mem = 0;
        Sel_MUX_Addr = 2'b00; // Default PC
        Bus_Sel = 2'b00; 
        Sel_MUX_X = 0; Sel_MUX_Y = 0;
        ALU_Op = opcode[4:0]; // Trecem 5 biti catre ALU
        next_state = FETCH;

        case (state)
            FETCH: begin
                Sel_MUX_Addr = 2'b00; // Punem PC-ul pe adresa memoriei
                W_IR = 1;             // Scriem in Instruction Register
                PC_Inc = 1;           // Incrementam PC pentru urmatoarea instructiune
                next_state = EXECUTE;
            end
            
            EXECUTE: begin
                case (opcode[5:4]) // Decodificare dupa primele 2 MSB
                    2'b00: begin // MEMORIE (0x00 - 0x0F)
                        if (opcode == 6'h00) begin // LDR
                            Sel_MUX_Addr = 2'b10; // Adresa din SignExtend
                            Bus_Sel = 2'b00;      // Datele vin din Memorie
                            if (reg_bit == 0) W_X = 1; else W_Y = 1;
                        end
                        else if (opcode == 6'h01) begin // STR
                            Sel_MUX_Addr = 2'b10;
                            Bus_Sel = (reg_bit == 0) ? 2'b10 : 2'b11; // Trebuie selectata sursa, adaptam simplificat
                            W_Mem = 1;
                        end
                        next_state = FETCH;
                    end
                    
                    2'b01, 2'b10: begin // ARITMETICE & LOGICE
                        // Rutam valorile din X si Y prin ALU
                        Sel_MUX_X = 0; 
                        Sel_MUX_Y = 0;
                        W_ACC = 1;      // Rezultatul se scrie in ACC
                        
                        // Protectie: CMP si TST nu scriu in ACC
                        if (opcode == 6'h17 || opcode == 6'h24) W_ACC = 0;
                        
                        W_Flags = 1;    // ALU actualizeaza flag-urile
                        next_state = FETCH;
                    end
                    
                    2'b11: begin // CONTROL FLOW
                        if (opcode == 6'h30 && Flags[0] == 1) PC_Load = 1;      // BRZ (Zero)
                        else if (opcode == 6'h31 && Flags[1] == 1) PC_Load = 1; // BRN (Negative)
                        else if (opcode == 6'h32 && Flags[2] == 1) PC_Load = 1; // BRC (Carry)
                        else if (opcode == 6'h33 && Flags[3] == 1) PC_Load = 1; // BRO (Overflow)
                        else if (opcode == 6'h34) PC_Load = 1;                  // BRA (Always)
                        else if (opcode == 6'h35) begin                         // JMP/CALL
                            SP_Push = 1;
                            W_Mem = 1;
                            Sel_MUX_Addr = 2'b01; // Adresa Mem = SP
                            PC_Load = 1;          // Incarca noua adresa in PC
                        end
                        else if (opcode == 6'h36) begin                         // RET
                            SP_Pop = 1;
                            Sel_MUX_Addr = 2'b01;
                            PC_Load = 1;
                        end
                        next_state = FETCH;
                    end
                endcase
            end
        endcase
    end
endmodule
