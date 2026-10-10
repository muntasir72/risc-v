`timescale 1ns/1ns

module pc_reg_tb;

    reg clk;
    reg reset;
    reg [31:0] pc_next;
    wire [31:0] pc;

    pc_reg uut(
        .clk(clk),
        .reset(reset),
        .pc_next(pc_next),
        .pc(pc)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 0;
        pc_next = 32'h00000000;

        #2 reset = 1;
        #10 reset = 0;

        pc_next = 32'h00000004;
        #10;

        pc_next = 32'h00000008;
        #10;

        pc_next = 32'h0000000C;
        #10;

        #2 reset = 1;
        #5 reset = 0;

        pc_next = 32'h00000010;
        #10;

        $finish;
    end

    initial begin
        $monitor("time = %0t | clk = %b | reset = %b | pc_next = %d | pc = %d",$time,clk,reset,pc_next,pc);
    end

endmodule