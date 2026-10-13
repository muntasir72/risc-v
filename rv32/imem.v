module imem (
    input wire [31:0] pc,           
    output wire [31:0] instr        
);
    reg [31:0] ROM [0:63];
    assign instr = ROM[pc[7:2]];   

    initial begin
        $readmemh("program.hex", ROM); 
    end
endmodule