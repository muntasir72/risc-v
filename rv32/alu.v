module alu (
    input wire [31:0] src_a, src_b, 
    input wire [5:0] alu_control, 
    output reg [31:0] alu_result 
);
    always @(*) begin
        case (alu_control)
            6'b000000: alu_result = src_a + src_b; // add / addi
            6'b000001: alu_result = src_a - src_b; // sub
            6'b000010: alu_result = src_a << src_b[4:0]; // sll / slli
            6'b000011: alu_result = ($signed(src_a) < $signed(src_b)) ? 32'b1 : 32'b0; // slt / slti
            6'b000100: alu_result = (src_a < src_b) ? 32'b1 : 32'b0; // sltu / sltui
            6'b000101: alu_result = src_a ^ src_b; // xor / xori
            6'b000110: alu_result = src_a >> src_b[4:0]; // srl / srli
            6'b000111: alu_result = $signed(src_a) >>> src_b[4:0]; // sra / srai
            6'b001000: alu_result = src_a | src_b; // or / ori
            6'b001001: alu_result = src_a & src_b; // and / andi
            
            default: alu_result = 32'b0;
        endcase
    end
endmodule