module imem (
    input wire [31:0] pc,           // value of pc
    output wire [31:0] instr        // instruction
);
    reg [31:0] ROM [63:0];
    assign instr = ROM[pc[7:2]];   // instruction gets the value at ROM[pc[7:2]]

    initial begin
        $readmemh("program.hex", ROM); // program.hex contains the instruction to be executed in 32bit hexadecimal format
    end
endmodule   