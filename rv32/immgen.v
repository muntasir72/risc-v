module immgen (
    input wire [31:0] instr,
    output reg [31:0] imm
);
    always @(*) begin
        if(instr[6:0] == 7'b0100011) begin
            imm = {{20{instr[31]}}, instr[31:25], instr[11:7]}; // S type instruction
        end
        else begin
            imm = {{20{instr[31]}}, instr[31:20]}; // I type instruction
        end
    end
endmodule