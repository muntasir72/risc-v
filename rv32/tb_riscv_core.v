`timescale 1ns / 1ps

module tb_riscv_core;

    reg clk;
    reg reset;

    riscv_core uut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("riscv_core_tb.vcd");
        $dumpvars(0, tb_riscv_core);

        clk = 0;
        reset = 1;

        #20;
        reset = 0;

        #200;
        
        $display("Simulation complete.");
        $finish;
    end

    always @(posedge clk) begin
        if (!reset) begin
            $display("Time: %0t ns | PC: 0x%0h | Instr: %h", $time, uut.pc, uut.instr);
        end
    end

endmodule