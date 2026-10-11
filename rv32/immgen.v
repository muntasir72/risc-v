module immgen (
    input wire [31:0] instr,
    output reg [31:0] imm
);
    wire [6:0] opcode = instr[6:0];

    always @(*) begin
        case (opcode)
            7'b0100011: // S-Type
                imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            7'b1100011: // B-Type
                imm = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
            7'b1101111: // J-Type
                imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
            7'b0110111, 7'b0010111: // U-Type (LUI, AUIPC)
                imm = {instr[31:12], 12'b0};
            default:    // I-Type (ALU, Loads, JALR)
                imm = {{20{instr[31]}}, instr[31:20]};
        endcase
    end
endmodule