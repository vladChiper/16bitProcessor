`timescale 1ns / 1ps

module tb_Datapath;

    // Semnale de test
    reg clk;
    reg reset;

    // Instantierea modulului principal (Design Under Test)
    Datapath uut (
        .clk(clk),
        .reset(reset)
    );

    // Generarea semnalului de ceas (Perioada de 10ns -> 100MHz)
    always #5 clk = ~clk;

    // Blocul principal de stimulare a semnalelor
    initial begin
        // Generare fisier VCD pentru vizualizarea formelor de unda (GTKWave / ModelSim)
        $dumpfile("processor.vcd");
        $dumpvars(0, tb_Datapath);

        // Initializare
        clk = 0;
        reset = 1;
        
        // Mentinem resetul activ un ciclu intreg pentru a stabiliza sistemul
        #10;
        reset = 0;

        // Lasam procesorul sa ruleze codul masina. 
        // 1000 ns (100 de cicluri de ceas) sunt suficiente pentru scriptul cod.txt
        #1000;
        
        // Oprim simularea
        $display("Simulare incheiata.");
        $finish;
    end

    // Monitorizare in consola (se afiseaza la fiecare schimbare de stare)
    initial begin
        $monitor("Time=%0t | PC=0x%04X | IR=0x%04X | X=%0d | Y=%0d | ACC=%0d | Flags(ZNCV)=%b", 
                 $time, uut.PC.pc_out, uut.REG_IR.data_out, uut.REG_X.data_out, uut.REG_Y.data_out, uut.REG_ACC.data_out, uut.Flags_Reg_Out);
    end

endmodule
