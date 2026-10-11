module branch_comp (
    input wire [31:0] rs1_data, rs2_data,
    input wire [2:0] func3,
    output reg br_taken
);
    always @(*) begin
        case (func3)
            3'b000: br_taken = (rs1_data == rs2_data);                  // BEQ
            3'b001: br_taken = (rs1_data != rs2_data);                  // BNE
            3'b100: br_taken = ($signed(rs1_data) < $signed(rs2_data)); // BLT
            3'b101: br_taken = ($signed(rs1_data) >= $signed(rs2_data));// BGE
            3'b110: br_taken = (rs1_data < rs2_data);                   // BLTU
            3'b111: br_taken = (rs1_data >= rs2_data);                  // BGEU
            default: br_taken = 1'b0;
        endcase
    end
endmodule