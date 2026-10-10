`timescale 1ns / 1ns

module tb_riscv_rtype_core();

    reg clk;
    reg reset;

    riscv_rtype_core uut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin

        clk = 0;
        reset = 1;

        $monitor("time = %0t | pc = %h | instr = %h | rs1_data = %0d | rs2_data = %0d | alu_out = %0d | reg_write = %b", $time, uut.pc, uut.instr, uut.rs1_data, uut.rs2_data, uut.alu_result, uut.reg_write);

        uut.rf.rf[1] = 32'd15;
        uut.rf.rf[2] = 32'd10;

        #15;
        reset = 0;

        #100;

        $finish;
    end

endmodule