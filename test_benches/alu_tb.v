`timescale 1ns/1ns

module alu_tb;
    reg  [31:0] src_a, src_b;
    reg  [5:0]  alu_control;
    wire [31:0] alu_result;

    alu uut (
        .src_a(src_a),
        .src_b(src_b),
        .alu_control(alu_control),
        .alu_result(alu_result)
    );

    task check_result;
        input [5:0]  control;
        input [31:0] a;
        input [31:0] b;
        input [31:0] expected;
        begin
            alu_control = control;
            src_a = a;
            src_b = b;
            #1;
            if (alu_result !== expected)
                $fatal(1,
                    "ALU failed: control=%06b src_a=%h src_b=%h expected=%h actual=%h",
                    control, a, b, expected, alu_result);
        end
    endtask

    initial begin
        check_result(6'b000000, 32'd7,          32'd4,          32'd11);          // ADD
        check_result(6'b000001, 32'd7,          32'd4,          32'd3);           // SUB
        check_result(6'b000010, 32'd1,          32'd4,          32'd16);          // SLL
        check_result(6'b000011, 32'hFFFFFFFF,   32'd1,          32'd1);           // SLT (signed -1 < 1)
        check_result(6'b000100, 32'hFFFFFFFF,   32'd1,          32'd0);           // SLTU (unsigned max < 1 is false)
        check_result(6'b000101, 32'hA5A5A5A5,   32'h0F0F0F0F,   32'hAAAAAAAA);    // XOR
        check_result(6'b000110, 32'h80000000,   32'd4,          32'h08000000);    // SRL
        check_result(6'b000111, 32'h80000000,   32'd4,          32'hF8000000);    // SRA
        check_result(6'b001000, 32'hF0F0F0F0,   32'h0F0F0F0F,   32'hFFFFFFFF);    // OR
        check_result(6'b001001, 32'hF0F0F0F0,   32'h0FF00FF0,   32'h00F000F0);    // AND
        check_result(6'b111111, 32'h12345678,   32'h87654321,   32'h00000000);    // Default case

        $display("alu_tb: all checks passed");
        $finish;
    end

    initial begin
        $monitor("time=%0t | src_a=%h | src_b=%h | alu_control=%06b | alu_result=%h",
                 $time, src_a, src_b, alu_control, alu_result);
    end
endmodule
