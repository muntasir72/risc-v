module imem (
    input wire [31:0] pc,           // RISC V inputs the PC as the address
    output wire [31:0] instr        // The output is the Instruction
);
    reg [31:0] ROM [63:0]; 
    assign instr = ROM[pc[7:2]];    // Divide by 4 to get array index
endmodule