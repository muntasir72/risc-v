`timescale 1ns / 1ps

module tb_riscv_core;

    // Testbench signals
    reg clk;
    reg reset;

    // Instantiate the Unit Under Test (UUT)
    riscv_core uut (
        .clk(clk),
        .reset(reset)
    );

    // Clock generation: 10ns period (100 MHz)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        reset = 1; // Assert reset initially

        // Hold reset for 10ns, then release to start execution
        #10;
        reset = 0;

        // Run the simulation for 500ns (adjust based on your program's length)
        #500;
        
        $display("Simulation finished.");
        $finish;
    end

    // Monitor the Program Counter to print execution progress to the console
    initial begin
        $monitor("Time = %0t | Reset = %b | PC = %h", $time, reset, uut.pc);
    end

    // Generate a VCD file to view waveforms in tools like GTKWave
    initial begin
        $dumpfile("riscv_core.vcd");
        $dumpvars(0, tb_riscv_core);
    end

endmodule