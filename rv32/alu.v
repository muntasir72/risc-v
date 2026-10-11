module alu (
    input wire [31:0] src_a, src_b, // alu inputs
    input wire [5:0] alu_control, // tells alu which instruction to execute
    output reg [31:0] alu_result // alu output
);
    always @(*) begin
        case (alu_control)
            6'b000000: alu_result = src_a + src_b; // add
            6'b000001: alu_result = src_a - src_b; // sub
            6'b000010: alu_result = src_a << src_b[4:0]; // sll
            6'b000011: alu_result = ($signed(src_a) < $signed(src_b)) ? 32'b1 : 32'b0; // slt
            6'b000100: alu_result = (src_a < src_b) ? 32'b1 : 32'b0; // sltu
            6'b000101: alu_result = src_a ^ src_b; // xor
            6'b000110: alu_result = src_a >> src_b[4:0]; // srl
            6'b000111: alu_result = $signed(src_a) >>> src_b[4:0]; // sra
            6'b001000: alu_result = src_a | src_b; // or
            6'b001001: alu_result = src_a & src_b; // and
            default: alu_result = 32'b0;
        endcase
    end
endmodule