module Memory (
    input clk,
    input we,              // Write Enable (pentru Store, Call etc.)
    input [15:0] addr,     // Adresa curenta
    input [15:0] data_in,  // Date de scris in memorie
    output [15:0] data_out // Date citite din memorie
);

    reg [15:0] ram [0:65535];
    integer i;

    initial begin
        // Initializam toata memoria cu 0 pentru a evita 'xxxx' in simulare
        for (i = 0; i < 65536; i = i + 1) begin
            ram[i] = 16'h0000;
        end
        // Incarcam codul masina generat de assembler
        $readmemh("../assembler/memorie.hex", ram);
    end

    always @(posedge clk) begin
        if (we) begin
            ram[addr] <= data_in;
        end
    end

    assign data_out = ram[addr];

endmodule
