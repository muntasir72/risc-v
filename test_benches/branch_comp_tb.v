`timescale 1ns/1ns
module branch_comp_tb;
    reg [31:0] rs1_data, rs2_data;
    reg [2:0] func3;
    wire br_taken;

    branch_comp uut (
        .rs1_data(rs1_data),
        .rs2_data(rs2_data),
        .func3(func3),
        .br_taken(br_taken)
    );

    task check_branch;
        input [2:0] op;
        input [31:0] a, b;
        input expected;
        input [160*8-1:0] test_name;
        begin
            func3 = op;
            rs1_data = a;
            rs2_data = b;
            #1;
            if (br_taken !== expected)
                $fatal(1, "branch_comp failed (%0s): func3=%b a=%h b=%h expected=%b got=%b",
                       test_name, op, a, b, expected, br_taken);
        end
    endtask

    initial begin
        check_branch(3'b000, 32'd5, 32'd5, 1'b1, "BEQ true");
        check_branch(3'b000, 32'd5, 32'd6, 1'b0, "BEQ false");
        check_branch(3'b001, 32'd5, 32'd6, 1'b1, "BNE true");
        check_branch(3'b001, 32'd5, 32'd5, 1'b0, "BNE false");
        check_branch(3'b100, -32'sd2, 32'd1, 1'b1, "BLT signed true");
        check_branch(3'b100, 32'd2, -32'sd1, 1'b0, "BLT signed false");
        check_branch(3'b101, 32'd2, -32'sd1, 1'b1, "BGE signed true");
        check_branch(3'b101, -32'sd2, 32'd1, 1'b0, "BGE signed false");
        check_branch(3'b110, 32'd1, 32'd2, 1'b1, "BLTU true");
        check_branch(3'b110, 32'hFFFFFFFF, 32'd1, 1'b0, "BLTU false");
        check_branch(3'b111, 32'hFFFFFFFF, 32'd1, 1'b1, "BGEU true");
        check_branch(3'b111, 32'd1, 32'hFFFFFFFF, 1'b0, "BGEU false");
        check_branch(3'b010, 32'd1, 32'd2, 1'b0, "default case");

        $display("branch_comp_tb: all checks passed");
        $finish;
    end
endmodule
