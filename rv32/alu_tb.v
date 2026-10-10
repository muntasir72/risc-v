`timescale 1ns/1ns

module alu_tb;

    reg [31:0] src_a, src_b;
    reg [2:0] alu_control;
    wire [31:0]alu_result;

    alu uut(
        .src_a(src_a),
        .src_b(src_b),
        .alu_control(alu_control),
        .alu_result(alu_result)
    );

    initial begin
        src_a = 32'h00000000;
        src_b = 32'h00000004;
        alu_control = 3'b111;
        #1;

        alu_control = 3'b000;
        #1;
        src_a = alu_result;
        #1;
        alu_control = 3'b001;
    end

    initial begin
        $monitor("time = %t | src_a = %h | src_b = %h | alu_control = %b | alu_result = %h", $time, src_a, src_b, alu_control, alu_result);
    end

endmodule