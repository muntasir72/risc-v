`timescale 1ns/1ns

module control_unit_tb;

    reg [6:0] opcode;
    reg [2:0] func3;
    reg [6:0] func7;
    wire reg_write;
    wire [2:0] alu_control;

    control_unit uut(
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .reg_write(reg_write),
        .alu_control(alu_control)
    );

    initial begin
        opcode = 7'b0000000;
        func3 = 3'b111;
        func7 = 7'b1111111;

        #1;

        opcode = 7'b0110011;
        func3 = 3'b000;
        func7 = 7'b0100000;

        #1;

        func3 = 3'b010;
        #1;
        func3 = 3'b110;
        func7 = 7'b0000000;
        #1;
        $finish;
    end

    initial begin
        $monitor("time = %t | opcode = %b | func3 = %b | func7 = %b | alu_control = %b | reg_write = %b",$time,opcode,func3,func7,alu_control,reg_write);
    end

endmodule