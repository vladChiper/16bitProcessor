`timescale 1ns / 1ps

module tb_Datapath;

    reg clk;
    reg reset;

    Datapath uut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("processor.vcd");
        $dumpvars(0, tb_Datapath);

        clk = 0;
        reset = 1;
        #10;
        reset = 0;

        // 500 ns (50 de cicluri de ceas) sunt suficiente pentru rularea testului complet
        #500;

        $display("Simulare incheiata cu succes.");
        $finish;
    end

    initial begin
        $monitor("Time=%0t | PC=0x%04X | IR=0x%04X | X=%0d | Y=%0d | ACC=%0d | SP=0x%04X | Flags(VCNZ)=%b",
                 $time, uut.PC.pc_out, uut.REG_IR.data_out, uut.REG_X.data_out, uut.REG_Y.data_out, uut.REG_ACC.data_out, uut.SP.sp_out, uut.Flags_Reg_Out);
    end

endmodule
