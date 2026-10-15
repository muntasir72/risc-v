`timescale 1ns/1ns
module immgen_tb;
    reg [31:0] instr;
    wire [31:0] imm;

    immgen uut (.instr(instr), .imm(imm));

    task check_imm;
        input [31:0] instruction;
        input [31:0] expected;
        input [160*8-1:0] test_name;
        begin
            instr = instruction;
            #1;
            if (imm !== expected)
                $fatal(1, "immgen failed (%0s): instr=%h expected=%h got=%h",
                       test_name, instruction, expected, imm);
        end
    endtask

    initial begin
        // I-type: immediate = sign-extended instr[31:20].
        check_imm(32'h00500093, 32'h00000005, "I-type positive");
        check_imm(32'hFFF00093, 32'hFFFFFFFF, "I-type negative");

        // S-type: imm = sign-extended {instr[31:25], instr[11:7]}.
        check_imm(32'hFE208FA3, 32'hFFFFFFFF, "S-type negative");

        // B-type: immediate bits are assembled with bit 0 = 0.
        check_imm(32'h00208463, 32'h00000008, "B-type positive");

        // U-type: upper 20 bits followed by 12 zeros.
        check_imm(32'h123450B7, 32'h12345000, "LUI");
        check_imm(32'hABCDE097, 32'hABCDE000, "AUIPC");

        // J-type: JAL x0, +8 (0x0080006F).
        check_imm(32'h0080006F, 32'h00000008, "J-type positive");

        $display("immgen_tb: all checks passed");
        $finish;
    end
endmodule
