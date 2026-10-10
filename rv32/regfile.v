module regfile (
    input wire clk,
    input wire reg_write,       
    input wire [4:0] rs1, rs2, rd,  // address of source 1, source 2, destination register
    input wire [31:0] write_data,   // data being written back
    output wire [31:0] rs1_data, rs2_data // data read from the registers
);
    reg [31:0] rf [31:0]; // our 32bit 32 registers

    assign rs1_data = (rs1 != 0) ? rf[rs1] : 32'b0;
    assign rs2_data = (rs2 != 0) ? rf[rs2] : 32'b0;
    
    always @(posedge clk) begin
        if (reg_write && rd != 0)
            rf[rd] <= write_data;
    end
endmodule