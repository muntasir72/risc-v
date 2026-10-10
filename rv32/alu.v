module alu (
    input wire [31:0] src_a, src_b, // alu inputs
    input wire [2:0] alu_control, // tells alu which instruction to execute
    output reg [31:0] alu_result    // alu output
);
    always @(*) begin
        case (alu_control)
            3'b000: alu_result = src_a + src_b;       // ADD
            3'b001: alu_result = src_a - src_b;       // SUB
            3'b010: alu_result = src_a & src_b;       // AND
            3'b011: alu_result = src_a | src_b;       // OR
            3'b101: alu_result = (src_a < src_b) ? 32'b1 : 32'b0; // SLT
            default: alu_result = 32'b0;
        endcase
    end
endmodule