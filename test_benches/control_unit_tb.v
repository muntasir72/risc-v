`timescale 1ns/1ns

module control_unit_tb;
    reg [6:0] opcode;
    reg [2:0] func3;
    reg [6:0] func7;

    wire reg_write, alu_src, mem_write, branch, jump;
    wire [1:0] result_src;
    wire [1:0] alu_src_a;
    wire [5:0] alu_control;

    control_unit uut (
        .opcode(opcode),
        .func3(func3),
        .func7(func7),
        .reg_write(reg_write),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .branch(branch),
        .jump(jump),
        .result_src(result_src),
        .alu_src_a(alu_src_a),
        .alu_control(alu_control)
    );

    task check_alu_decode;
        input [6:0] op;
        input [2:0] f3;
        input [6:0] f7;
        input [5:0] expected_control;
        input expected_reg_write;
        input expected_alu_src;
        begin
            opcode = op;
            func3 = f3;
            func7 = f7;
            #1;
            if (alu_control !== expected_control)
                $fatal(1, "Control decode failed: opcode=%07b func3=%03b func7=%07b expected alu_control=%06b got=%06b",
                       op, f3, f7, expected_control, alu_control);
            if (reg_write !== expected_reg_write)
                $fatal(1, "reg_write failed: opcode=%07b expected=%b got=%b",
                       op, expected_reg_write, reg_write);
            if (alu_src !== expected_alu_src)
                $fatal(1, "alu_src failed: opcode=%07b expected=%b got=%b",
                       op, expected_alu_src, alu_src);
        end
    endtask

    initial begin
        // Unsupported opcode: safe defaults.
        opcode = 7'b0000000;
        func3 = 3'b000;
        func7 = 7'b0000000;
        #1;
        if (reg_write !== 1'b0 || alu_src !== 1'b0 || mem_write !== 1'b0 ||
            branch !== 1'b0 || jump !== 1'b0 || result_src !== 2'b00 ||
            alu_src_a !== 2'b00 || alu_control !== 6'b111111)
            $fatal(1, "Unsupported-opcode defaults failed");

        // R-type control decodes.
        check_alu_decode(7'b0110011, 3'b000, 7'b0000000, 6'b000000, 1'b1, 1'b0); // ADD
        check_alu_decode(7'b0110011, 3'b000, 7'b0100000, 6'b000001, 1'b1, 1'b0); // SUB
        check_alu_decode(7'b0110011, 3'b001, 7'b0000000, 6'b000010, 1'b1, 1'b0); // SLL
        check_alu_decode(7'b0110011, 3'b010, 7'b0000000, 6'b000011, 1'b1, 1'b0); // SLT
        check_alu_decode(7'b0110011, 3'b011, 7'b0000000, 6'b000100, 1'b1, 1'b0); // SLTU
        check_alu_decode(7'b0110011, 3'b100, 7'b0000000, 6'b000101, 1'b1, 1'b0); // XOR
        check_alu_decode(7'b0110011, 3'b101, 7'b0000000, 6'b000110, 1'b1, 1'b0); // SRL
        check_alu_decode(7'b0110011, 3'b101, 7'b0100000, 6'b000111, 1'b1, 1'b0); // SRA
        check_alu_decode(7'b0110011, 3'b110, 7'b0000000, 6'b001000, 1'b1, 1'b0); // OR
        check_alu_decode(7'b0110011, 3'b111, 7'b0000000, 6'b001001, 1'b1, 1'b0); // AND

        // I-type ADDI uses the immediate as ALU source B.
        check_alu_decode(7'b0010011, 3'b000, 7'b0000000, 6'b000000, 1'b1, 1'b1);

        // Load instruction.
        opcode = 7'b0000011; func3 = 3'b010; func7 = 7'b0000000; #1;
        if (reg_write !== 1'b1 || alu_src !== 1'b1 || mem_write !== 1'b0 ||
            result_src !== 2'b01 || alu_control !== 6'b000000)
            $fatal(1, "Load control check failed");

        // Store instruction.
        opcode = 7'b0100011; func3 = 3'b010; func7 = 7'b0000000; #1;
        if (reg_write !== 1'b0 || alu_src !== 1'b1 || mem_write !== 1'b1 ||
            alu_control !== 6'b000000)
            $fatal(1, "Store control check failed");

        // Branch instruction. This module leaves alu_control at its default for branches.
        opcode = 7'b1100011; func3 = 3'b000; func7 = 7'b0000000; #1;
        if (branch !== 1'b1 || reg_write !== 1'b0 || alu_control !== 6'b111111)
            $fatal(1, "Branch control check failed");

        // JAL instruction.
        opcode = 7'b1101111; func3 = 3'b000; func7 = 7'b0000000; #1;
        if (jump !== 1'b1 || reg_write !== 1'b1 || result_src !== 2'b10)
            $fatal(1, "JAL control check failed");

        // JALR instruction.
        opcode = 7'b1100111; func3 = 3'b000; func7 = 7'b0000000; #1;
        if (jump !== 1'b1 || reg_write !== 1'b1 || result_src !== 2'b10 ||
            alu_src !== 1'b1 || alu_control !== 6'b000000)
            $fatal(1, "JALR control check failed");

        // LUI selects constant zero for ALU source A.
        opcode = 7'b0110111; func3 = 3'b000; func7 = 7'b0000000; #1;
        if (reg_write !== 1'b1 || alu_src !== 1'b1 || alu_src_a !== 2'b10 ||
            alu_control !== 6'b000000)
            $fatal(1, "LUI control check failed");

        // AUIPC selects the PC for ALU source A.
        opcode = 7'b0010111; func3 = 3'b000; func7 = 7'b0000000; #1;
        if (reg_write !== 1'b1 || alu_src !== 1'b1 || alu_src_a !== 2'b01 ||
            alu_control !== 6'b000000)
            $fatal(1, "AUIPC control check failed");

        $display("control_unit_tb: all checks passed");
        $finish;
    end

    initial begin
        $monitor("time=%0t | opcode=%07b | func3=%03b | func7=%07b | alu_control=%06b | reg_write=%b | alu_src=%b | mem_write=%b | branch=%b | jump=%b | result_src=%02b | alu_src_a=%02b",
                 $time, opcode, func3, func7, alu_control, reg_write, alu_src,
                 mem_write, branch, jump, result_src, alu_src_a);
    end
endmodule
