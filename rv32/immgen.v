module immgen (
    input wire [31:0] instr,
    output reg [31:0] imm
);
    always @(*) begin
        // the value of sign bit (instr[31] is extended 20 times)
        imm = {{20{instr[31]}}, instr[31:20]};
    end
endmodule