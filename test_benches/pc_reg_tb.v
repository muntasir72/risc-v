`timescale 1ns/1ns
module pc_reg_tb;
    reg clk;
    reg reset;
    reg [31:0] pc_next;
    wire [31:0] pc;

    pc_reg uut(.clk(clk), .reset(reset), .pc_next(pc_next), .pc(pc));
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        reset = 0;
        pc_next = 32'h0;

        #2 reset = 1;
        #1;
        if (pc !== 32'h00000000)
            $fatal(1, "PC reset check failed: expected 00000000, got %h", pc);
        @(negedge clk);
        reset = 0;

        pc_next = 32'h00000004;
        @(posedge clk); #1;
        if (pc !== 32'h00000004)
            $fatal(1, "PC update failed: expected 00000004, got %h", pc);

        pc_next = 32'h00000008;
        @(posedge clk); #1;
        if (pc !== 32'h00000008)
            $fatal(1, "PC update failed: expected 00000008, got %h", pc);

        pc_next = 32'h0000000C;
        @(posedge clk); #1;
        if (pc !== 32'h0000000C)
            $fatal(1, "PC update failed: expected 0000000C, got %h", pc);

        @(negedge clk);
        reset = 1;
        #1;
        if (pc !== 32'h00000000)
            $fatal(1, "PC reset check failed: expected 00000000, got %h", pc);
        @(negedge clk);
        reset = 0;

        pc_next = 32'h00000010;
        @(posedge clk); #1;
        if (pc !== 32'h00000010)
            $fatal(1, "PC update failed: expected 00000010, got %h", pc);

        $display("pc_reg_tb: all checks passed");
        $finish;
    end

    initial $monitor("time = %0t | clk = %b | reset = %b | pc_next = %d | pc = %d",
                     $time, clk, reset, pc_next, pc);
endmodule
