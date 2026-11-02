module Memory (
    input clk,
    input we,              // Write Enable (pentru Store, Call etc.)
    input [15:0] addr,     // Adresa curenta (selectata prin MUX intre PC, SP si altele)
    input [15:0] data_in,  // Date de scris in memorie
    output [15:0] data_out // Date citite din memorie
);

    // Memorie RAM - 65536 adrese a cate 16 biti
    reg [15:0] ram [0:65535];

    initial begin
        // Incarcam binarul generat de assembler in memorie la startul simularii.
        // Calea relativa presupune ca rulezi simularea din folderul 'hw'.
        $readmemh("../assembler/memorie.hex", ram);
    end

    // Procesul de scriere (sincron - se intampla pe frontul de ceas)
    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= data_in;
        end
    end

    // Procesul de citire (asincron/combinational)
    // Este obligatoriu combinational pentru ca Unitatea de Control sa poata 
    // decodifica instructiunea (Fetch) in acelasi ciclu in care PC-ul o cere.
    assign data_out = ram[addr];

endmodule
