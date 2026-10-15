`timescale 1ns/1ns
module imem_tb;
    reg [31:0] pc;
    wire [31:0] instr;

    imem uut (.pc(pc), .instr(instr));

    initial begin
        // Replace selected ROM words after the DUT's $readmemh initialization,
        // so this test is deterministic and does not depend on program.hex.
        #1;
        uut.ROM[0] = 32'h00500093;
        uut.ROM[1] = 32'h00700113;
        uut.ROM[2] = 32'h002081B3;

        pc = 32'h00000000;
        #1;
        if (instr !== 32'h00500093)
            $fatal(1, "IMEM word 0 failed: expected 00500093, got %h", instr);

        pc = 32'h00000004;
        #1;
        if (instr !== 32'h00700113)
            $fatal(1, "IMEM word 1 failed: expected 00700113, got %h", instr);

        pc = 32'h00000008;
        #1;
        if (instr !== 32'h002081B3)
            $fatal(1, "IMEM word 2 failed: expected 002081B3, got %h", instr);

        // The implementation indexes ROM using pc[7:2], so low PC bits
        // do not change the selected instruction.
        pc = 32'h00000009;
        #1;
        if (instr !== 32'h002081B3)
            $fatal(1, "IMEM PC indexing check failed: expected 002081B3, got %h", instr);

        $display("imem_tb: all checks passed");
        $finish;
    end
endmodule
