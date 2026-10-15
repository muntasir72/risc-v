`timescale 1ns/1ns
module regfile_tb;
    reg clk;
    reg reg_write;
    reg [4:0] rs1, rs2, rd;
    reg [31:0] write_data;
    wire [31:0] rs1_data, rs2_data;

    regfile uut(.clk(clk), .reg_write(reg_write), .rs1(rs1), .rs2(rs2),
                .rd(rd), .write_data(write_data), .rs1_data(rs1_data),
                .rs2_data(rs2_data));
    always #5 clk = ~clk;

    task write_reg;
        input [4:0] addr;
        input [31:0] data;
        begin
            @(negedge clk);
            rd = addr;
            write_data = data;
            reg_write = 1'b1;
            @(posedge clk);
            #1;
            reg_write = 1'b0;
        end
    endtask

    initial begin
        clk = 0;
        reg_write = 0;
        rs1 = 5'd1;
        rs2 = 5'd2;
        rd = 0;
        write_data = 0;

        write_reg(5'd1, 32'd4);
        write_reg(5'd2, 32'd8);

        rs1 = 5'd1;
        rs2 = 5'd2;
        #1;
        if (rs1_data !== 32'd4)
            $fatal(1, "Register x1 check failed: expected 4, got %d", rs1_data);
        if (rs2_data !== 32'd8)
            $fatal(1, "Register x2 check failed: expected 8, got %d", rs2_data);

        write_reg(5'd3, rs1_data + rs2_data);
        rs1 = 5'd3;
        rs2 = 5'd0;
        #1;
        if (rs1_data !== 32'd12)
            $fatal(1, "Register x3 check failed: expected 12, got %d", rs1_data);
        if (rs2_data !== 32'd0)
            $fatal(1, "Register x0 check failed: expected 0, got %d", rs2_data);

        $display("regfile_tb: all checks passed");
        $finish;
    end

    initial $monitor("time = %0t | clk = %b | reg_write = %b | rs1_data = %h | rs2_data = %h | write_data = %d",
                     $time, clk, reg_write, rs1_data, rs2_data, write_data);
endmodule
