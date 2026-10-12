`timescale 1ns / 1ps

// Self-checking bench for riscv_core.
// The first program is program.hex, loaded by imem at time 0.
// Later programs are written into uut.imem.ROM while reset is held.
// Register and data-memory results are read hierarchically, same idea as
// the other benches that poke uut.rf.rf[].

module tb_riscv_core;

    reg clk;
    reg reset;
    reg [31:0] exp_rf [0:31];
    integer pass_count;
    integer fail_count;

    riscv_core uut (
        .clk(clk),
        .reset(reset)
    );

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (!reset) begin
            $display("Time: %0d ns | PC: 0x%h | Instr: %h", $time, uut.pc, uut.instr);
        end
    end

    task clear_arch;
        integer ri;
        begin
            for (ri = 0; ri < 32; ri = ri + 1)
                uut.rf.rf[ri] = 32'b0;
            for (ri = 0; ri < 64; ri = ri + 1)
                uut.dm.RAM[ri] = 32'b0;
        end
    endtask

    task fill_nops;
        integer ri;
        begin
            for (ri = 0; ri < 64; ri = ri + 1)
                uut.imem.ROM[ri] = 32'h00000013; // addi x0, x0, 0
        end
    endtask

    task clear_exp;
        integer ri;
        begin
            for (ri = 0; ri < 32; ri = ri + 1)
                exp_rf[ri] = 32'b0;
        end
    endtask

    // Drop reset on the falling edge so the next rising edge is the first
    // commit of the program under test. regfile and dmem ignore reset, so
    // state is cleared after the edge that happens while reset is still high.
    task hold_reset_and_clear;
        begin
            reset = 1;
            @(posedge clk);
            #1;
            clear_arch;
            fill_nops;
        end
    endtask

    task release_reset;
        begin
            @(negedge clk);
            reset = 0;
            #1;
        end
    endtask

    task run_n;
        input integer n;
        integer s;
        begin
            for (s = 0; s < n; s = s + 1) begin
                @(posedge clk);
                #1;
            end
        end
    endtask

    task run_straight;
        input integer n;
        integer s;
        integer bad;
        reg [31:0] prev_pc;
        begin
            bad = 0;
            for (s = 0; s < n; s = s + 1) begin
                prev_pc = uut.pc;
                @(posedge clk);
                #1;
                if (uut.pc !== (prev_pc + 32'd4)) begin
                    bad = bad + 1;
                    $display("FAIL: sequential PC after instruction %0d got 0x%h expected 0x%h",
                             s, uut.pc, prev_pc + 32'd4);
                end
            end
            if (bad == 0) begin
                pass_count = pass_count + n;
                $display("PASS: PC + 4 for %0d instructions, final PC 0x%h", n, uut.pc);
            end else begin
                pass_count = pass_count + (n - bad);
                fail_count = fail_count + bad;
            end
        end
    endtask

    task check_pc;
        input [31:0] expected;
        begin
            if (uut.pc === expected) begin
                pass_count = pass_count + 1;
                $display("PASS: PC = 0x%h", expected);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: PC got 0x%h expected 0x%h", uut.pc, expected);
            end
        end
    endtask

    task check_instr;
        input [31:0] expected;
        begin
            if (uut.instr === expected) begin
                pass_count = pass_count + 1;
                $display("PASS: instr = 0x%h", expected);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: instr got 0x%h expected 0x%h", uut.instr, expected);
            end
        end
    endtask

    task check_reg;
        input integer n;
        input [31:0] expected;
        begin
            if (uut.rf.rf[n] === expected) begin
                pass_count = pass_count + 1;
                $display("PASS: x%0d = 0x%h", n, expected);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: x%0d got 0x%h expected 0x%h", n, uut.rf.rf[n], expected);
            end
        end
    endtask

    task check_regs;
        integer r;
        begin
            for (r = 0; r < 32; r = r + 1)
                check_reg(r, exp_rf[r]);
        end
    endtask

    task check_ram;
        input integer idx;
        input [31:0] expected;
        begin
            if (uut.dm.RAM[idx] === expected) begin
                pass_count = pass_count + 1;
                $display("PASS: dmem[%0d] = 0x%h", idx, expected);
            end else begin
                fail_count = fail_count + 1;
                $display("FAIL: dmem[%0d] got 0x%h expected 0x%h", idx, uut.dm.RAM[idx], expected);
            end
        end
    endtask

    task set_exp;
        input integer n;
        input [31:0] value;
        begin
            exp_rf[n] = value;
        end
    endtask

    initial begin
        #200000;
        $display("FAIL: simulation timeout");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        $finish;
    end

    initial begin
        $dumpfile("riscv_core_tb.vcd");
        $dumpvars(0, tb_riscv_core);

        pass_count = 0;
        fail_count = 0;
        clk = 0;
        reset = 1;

        // program.hex is read by imem at time 0. Wait until that has happened.
        #1;
        clear_arch;

        $display("-------- reset --------");
        check_pc(32'd0);
        check_instr(32'h00A00093); // addi x1, x0, 10

        @(posedge clk);
        #1;
        check_pc(32'd0);
        // regfile has no reset, so this edge still commits the instruction at PC 0.
        $display("NOTE: clock while reset is held, PC = 0x%h, x1 = 0x%h", uut.pc, uut.rf.rf[1]);

        clear_arch;
        @(negedge clk);
        reset = 0;
        #1;
        check_pc(32'd0);
        check_instr(32'h00A00093);

        // program.hex:
        //   addi x1, x0, 10
        //   addi x2, x0, 20
        //   add  x3, x1, x2
        //   sub  x4, x2, x1
        //   and  x5, x1, x3
        //   or   x6, x1, x2
        //   xor  x7, x2, x3
        //   sw   x3, 16(x0)
        //   lw   x8, 16(x0)
        //   beq  x3, x8, +8      ; skips addi x1, x0, 99
        //   jal  x9, +8          ; skips addi x2, x0, 99
        //   jal  x0, 0
        $display("-------- program.hex --------");
        run_straight(9);
        check_pc(32'd36);
        run_n(1);
        check_pc(32'd44); // beq taken
        run_n(1);
        check_pc(32'd52); // jal x9, +8

        clear_exp;
        set_exp(1, 32'd10);
        set_exp(2, 32'd20);
        set_exp(3, 32'd30);
        set_exp(4, 32'd10);
        set_exp(5, 32'd10);
        set_exp(6, 32'd30);
        set_exp(7, 32'd10);
        set_exp(8, 32'd30);
        set_exp(9, 32'd48); // link from the jal at PC 44
        check_regs;
        check_ram(4, 32'd30); // sw x3, 16(x0)
        check_ram(0, 32'd0);
        check_ram(3, 32'd0);
        check_ram(5, 32'd0);

        run_n(1);
        check_pc(32'd52); // jal x0, 0 stays put
        check_reg(1, 32'd10);
        check_reg(2, 32'd20);

        // addi x1, x0, -1 / 2047 / -2048, then R-type and I-type ops
        $display("-------- alu and immediates --------");
        hold_reset_and_clear;
        uut.imem.ROM[ 0] = 32'hFFF00093; // addi x1, x0, -1
        uut.imem.ROM[ 1] = 32'h7FF00113; // addi x2, x0, 2047
        uut.imem.ROM[ 2] = 32'h80000193; // addi x3, x0, -2048
        uut.imem.ROM[ 3] = 32'h00208233; // add  x4, x1, x2
        uut.imem.ROM[ 4] = 32'h00108293; // addi x5, x1, 1
        uut.imem.ROM[ 5] = 32'h0F00E313; // ori  x6, x1, 0x0F0
        uut.imem.ROM[ 6] = 32'h0FF17393; // andi x7, x2, 0x0FF
        uut.imem.ROM[ 7] = 32'hFFF14413; // xori x8, x2, -1
        uut.imem.ROM[ 8] = 32'h00100493; // addi x9, x0, 1
        uut.imem.ROM[ 9] = 32'h00400513; // addi x10, x0, 4
        uut.imem.ROM[10] = 32'h00A495B3; // sll  x11, x9, x10
        uut.imem.ROM[11] = 32'h01F49613; // slli x12, x9, 31
        uut.imem.ROM[12] = 32'h01F65693; // srli x13, x12, 31
        uut.imem.ROM[13] = 32'h41F65713; // srai x14, x12, 31
        uut.imem.ROM[14] = 32'hFF800793; // addi x15, x0, -8
        uut.imem.ROM[15] = 32'h00A79833; // sll  x16, x15, x10
        uut.imem.ROM[16] = 32'h00A7D8B3; // srl  x17, x15, x10
        uut.imem.ROM[17] = 32'h40A7D933; // sra  x18, x15, x10
        uut.imem.ROM[18] = 32'h00479993; // slli x19, x15, 4
        uut.imem.ROM[19] = 32'h0047DA13; // srli x20, x15, 4
        uut.imem.ROM[20] = 32'h4047DA93; // srai x21, x15, 4
        uut.imem.ROM[21] = 32'h0090AB33; // slt  x22, x1, x9
        uut.imem.ROM[22] = 32'h0090BBB3; // sltu x23, x1, x9
        uut.imem.ROM[23] = 32'h0014AC33; // slt  x24, x9, x1
        uut.imem.ROM[24] = 32'h0014BCB3; // sltu x25, x9, x1
        uut.imem.ROM[25] = 32'h0010AD13; // slti x26, x1, 1
        uut.imem.ROM[26] = 32'h0010BD93; // sltiu x27, x1, 1
        uut.imem.ROM[27] = 32'h0014AE13; // slti x28, x9, 1
        uut.imem.ROM[28] = 32'h0024BE93; // sltiu x29, x9, 2
        uut.imem.ROM[29] = 32'h0010AF33; // slt  x30, x1, x1
        uut.imem.ROM[30] = 32'h12345FB7; // lui  x31, 0x12345
        release_reset;
        check_pc(32'd0);
        check_instr(32'hFFF00093);
        run_straight(31);
        clear_exp;
        set_exp(1,  32'hFFFFFFFF);
        set_exp(2,  32'h000007FF);
        set_exp(3,  32'hFFFFF800);
        set_exp(4,  32'h000007FE);
        set_exp(6,  32'hFFFFFFFF);
        set_exp(7,  32'h000000FF);
        set_exp(8,  32'hFFFFF800);
        set_exp(9,  32'h00000001);
        set_exp(10, 32'h00000004);
        set_exp(11, 32'h00000010);
        set_exp(12, 32'h80000000);
        set_exp(13, 32'h00000001);
        set_exp(14, 32'hFFFFFFFF);
        set_exp(15, 32'hFFFFFFF8);
        set_exp(16, 32'hFFFFFF80);
        set_exp(17, 32'h0FFFFFFF);
        set_exp(18, 32'hFFFFFFFF);
        set_exp(19, 32'hFFFFFF80);
        set_exp(20, 32'h0FFFFFFF);
        set_exp(21, 32'hFFFFFFFF);
        set_exp(22, 32'h00000001);
        set_exp(25, 32'h00000001);
        set_exp(26, 32'h00000001);
        set_exp(29, 32'h00000001);
        set_exp(31, 32'h12345000);
        check_regs;
        check_ram(0, 32'd0);

        $display("-------- lui and auipc --------");
        hold_reset_and_clear;
        uut.imem.ROM[0] = 32'h123450B7; // lui   x1, 0x12345
        uut.imem.ROM[1] = 32'h00000117; // auipc x2, 0
        uut.imem.ROM[2] = 32'h00001197; // auipc x3, 1
        uut.imem.ROM[3] = 32'hFFF08213; // addi  x4, x1, -1
        uut.imem.ROM[4] = 32'h800002B7; // lui   x5, 0x80000
        uut.imem.ROM[5] = 32'h00528333; // add   x6, x5, x5
        release_reset;
        check_pc(32'd0);
        run_straight(6);
        clear_exp;
        set_exp(1, 32'h12345000);
        set_exp(2, 32'd4);          // auipc at PC 4, imm 0
        set_exp(3, 32'h00001008);   // auipc at PC 8, imm 0x1000
        set_exp(4, 32'h12344FFF);
        set_exp(5, 32'h80000000);
        check_regs;

        $display("-------- data dependencies --------");
        hold_reset_and_clear;
        uut.imem.ROM[0] = 32'h00100093; // addi x1, x0, 1
        uut.imem.ROM[1] = 32'h00108093; // addi x1, x1, 1
        uut.imem.ROM[2] = 32'h00108093; // addi x1, x1, 1
        uut.imem.ROM[3] = 32'h00108093; // addi x1, x1, 1
        uut.imem.ROM[4] = 32'h00108133; // add  x2, x1, x1
        uut.imem.ROM[5] = 32'h401101B3; // sub  x3, x2, x1
        release_reset;
        check_pc(32'd0);
        run_straight(6);
        clear_exp;
        set_exp(1, 32'd4);
        set_exp(2, 32'd8);
        set_exp(3, 32'd4);
        check_regs;

        $display("-------- loads and stores --------");
        hold_reset_and_clear;
        uut.imem.ROM[ 0] = 32'hF8000093; // addi x1, x0, -128
        uut.imem.ROM[ 1] = 32'h00100023; // sb   x1, 0(x0)
        uut.imem.ROM[ 2] = 32'h00000103; // lb   x2, 0(x0)
        uut.imem.ROM[ 3] = 32'h00004183; // lbu  x3, 0(x0)
        uut.imem.ROM[ 4] = 32'h001002A3; // sb   x1, 5(x0)
        uut.imem.ROM[ 5] = 32'h00500203; // lb   x4, 5(x0)
        uut.imem.ROM[ 6] = 32'h00504283; // lbu  x5, 5(x0)
        uut.imem.ROM[ 7] = 32'h00101423; // sh   x1, 8(x0)
        uut.imem.ROM[ 8] = 32'h00801303; // lh   x6, 8(x0)
        uut.imem.ROM[ 9] = 32'h00805383; // lhu  x7, 8(x0)
        uut.imem.ROM[10] = 32'h12345437; // lui  x8, 0x12345
        uut.imem.ROM[11] = 32'h67840413; // addi x8, x8, 0x678
        uut.imem.ROM[12] = 32'h00802623; // sw   x8, 12(x0)
        uut.imem.ROM[13] = 32'h00C02483; // lw   x9, 12(x0)
        uut.imem.ROM[14] = 32'h00C00513; // addi x10, x0, 12
        uut.imem.ROM[15] = 32'h00052583; // lw   x11, 0(x10)
        uut.imem.ROM[16] = 32'h00158633; // add  x12, x11, x1
        uut.imem.ROM[17] = 32'h00100623; // sb   x1, 12(x0)
        uut.imem.ROM[18] = 32'h00C02683; // lw   x13, 12(x0)
        uut.imem.ROM[19] = 32'h0FC00713; // addi x14, x0, 252
        uut.imem.ROM[20] = 32'h00872023; // sw   x8, 0(x14)
        uut.imem.ROM[21] = 32'h00072783; // lw   x15, 0(x14)
        uut.imem.ROM[22] = 32'h001701A3; // sb   x1, 3(x14)   ; address 255
        uut.imem.ROM[23] = 32'h00370803; // lb   x16, 3(x14)
        uut.imem.ROM[24] = 32'h00072883; // lw   x17, 0(x14)
        uut.imem.ROM[25] = 32'h00101523; // sh   x1, 10(x0)
        uut.imem.ROM[26] = 32'h00A01903; // lh   x18, 10(x0)
        uut.imem.ROM[27] = 32'h00A05983; // lhu  x19, 10(x0)
        uut.imem.ROM[28] = 32'h00802A03; // lw   x20, 8(x0)
        release_reset;
        check_pc(32'd0);
        run_straight(29);
        clear_exp;
        set_exp(1,  32'hFFFFFF80);
        set_exp(2,  32'hFFFFFF80);
        set_exp(3,  32'h00000080);
        set_exp(4,  32'hFFFFFF80);
        set_exp(5,  32'h00000080);
        set_exp(6,  32'hFFFFFF80);
        set_exp(7,  32'h0000FF80);
        set_exp(8,  32'h12345678);
        set_exp(9,  32'h12345678);
        set_exp(10, 32'd12);
        set_exp(11, 32'h12345678);
        set_exp(12, 32'h123455F8);
        set_exp(13, 32'h12345680);
        set_exp(14, 32'd252);
        set_exp(15, 32'h12345678);
        set_exp(16, 32'hFFFFFF80);
        set_exp(17, 32'h80345678);
        set_exp(18, 32'hFFFFFF80);
        set_exp(19, 32'h0000FF80);
        set_exp(20, 32'hFF80FF80);
        check_regs;
        check_ram(0,  32'h00000080);
        check_ram(1,  32'h00008000);
        check_ram(2,  32'hFF80FF80);
        check_ram(3,  32'h12345680);
        check_ram(63, 32'h80345678);
        check_ram(4,  32'd0);

        // Taken branches skip `addi rd, x0, 1`. Not-taken branches execute
        // the following addi. The last pair checks bgeu not taken.
        $display("-------- branches --------");
        hold_reset_and_clear;
        uut.imem.ROM[ 0] = 32'h00500093; // addi x1, x0, 5
        uut.imem.ROM[ 1] = 32'h00500113; // addi x2, x0, 5
        uut.imem.ROM[ 2] = 32'h00400193; // addi x3, x0, 4
        uut.imem.ROM[ 3] = 32'h00208463; // beq  x1, x2, 8
        uut.imem.ROM[ 4] = 32'h00100213; // addi x4, x0, 1
        uut.imem.ROM[ 5] = 32'h00200293; // addi x5, x0, 2
        uut.imem.ROM[ 6] = 32'h00209463; // bne  x1, x2, 8
        uut.imem.ROM[ 7] = 32'h00300313; // addi x6, x0, 3
        uut.imem.ROM[ 8] = 32'h00309463; // bne  x1, x3, 8
        uut.imem.ROM[ 9] = 32'h00100393; // addi x7, x0, 1
        uut.imem.ROM[10] = 32'h00400413; // addi x8, x0, 4
        uut.imem.ROM[11] = 32'h0011C463; // blt  x3, x1, 8
        uut.imem.ROM[12] = 32'h00100493; // addi x9, x0, 1
        uut.imem.ROM[13] = 32'h00600513; // addi x10, x0, 6
        uut.imem.ROM[14] = 32'h0030D463; // bge  x1, x3, 8
        uut.imem.ROM[15] = 32'h00100593; // addi x11, x0, 1
        uut.imem.ROM[16] = 32'h00700613; // addi x12, x0, 7
        uut.imem.ROM[17] = 32'h0030C463; // blt  x1, x3, 8
        uut.imem.ROM[18] = 32'h00800693; // addi x13, x0, 8
        uut.imem.ROM[19] = 32'hFFF00713; // addi x14, x0, -1
        uut.imem.ROM[20] = 32'h00E0E463; // bltu x1, x14, 8
        uut.imem.ROM[21] = 32'h00100793; // addi x15, x0, 1
        uut.imem.ROM[22] = 32'h00900813; // addi x16, x0, 9
        uut.imem.ROM[23] = 32'h00177463; // bgeu x14, x1, 8
        uut.imem.ROM[24] = 32'h00100893; // addi x17, x0, 1
        uut.imem.ROM[25] = 32'h00A00913; // addi x18, x0, 10
        uut.imem.ROM[26] = 32'h00176463; // bltu x14, x1, 8
        uut.imem.ROM[27] = 32'h00B00993; // addi x19, x0, 11
        uut.imem.ROM[28] = 32'h00175463; // bge  x14, x1, 8
        uut.imem.ROM[29] = 32'h00C00A13; // addi x20, x0, 12
        uut.imem.ROM[30] = 32'h0010D463; // bge  x1, x1, 8
        uut.imem.ROM[31] = 32'h00100A93; // addi x21, x0, 1
        uut.imem.ROM[32] = 32'h00D00B13; // addi x22, x0, 13
        uut.imem.ROM[33] = 32'h00308463; // beq  x1, x3, 8
        uut.imem.ROM[34] = 32'h00E00B93; // addi x23, x0, 14
        uut.imem.ROM[35] = 32'hFFB00C13; // addi x24, x0, -5
        uut.imem.ROM[36] = 32'hFFD00C93; // addi x25, x0, -3
        uut.imem.ROM[37] = 32'h019C4463; // blt  x24, x25, 8
        uut.imem.ROM[38] = 32'h00100D13; // addi x26, x0, 1
        uut.imem.ROM[39] = 32'h00F00D93; // addi x27, x0, 15
        uut.imem.ROM[40] = 32'h018CD463; // bge  x25, x24, 8
        uut.imem.ROM[41] = 32'h00100E13; // addi x28, x0, 1
        uut.imem.ROM[42] = 32'h01000E93; // addi x29, x0, 16
        uut.imem.ROM[43] = 32'h0010F463; // bgeu x1, x1, 8
        uut.imem.ROM[44] = 32'h00100F13; // addi x30, x0, 1
        uut.imem.ROM[45] = 32'h01100F93; // addi x31, x0, 17
        uut.imem.ROM[46] = 32'h0010E463; // bltu x1, x1, 8
        uut.imem.ROM[47] = 32'h01200F13; // addi x30, x0, 18
        uut.imem.ROM[48] = 32'h00E0F463; // bgeu x1, x14, 8
        uut.imem.ROM[49] = 32'h01300213; // addi x4, x0, 19
        release_reset;
        check_pc(32'd0);
        run_n(38);
        check_pc(32'd192);
        clear_exp;
        set_exp(1,  32'd5);
        set_exp(2,  32'd5);
        set_exp(3,  32'd4);
        set_exp(5,  32'd2);
        set_exp(6,  32'd3);
        set_exp(8,  32'd4);
        set_exp(10, 32'd6);
        set_exp(12, 32'd7);
        set_exp(13, 32'd8);
        set_exp(14, 32'hFFFFFFFF);
        set_exp(16, 32'd9);
        set_exp(18, 32'd10);
        set_exp(19, 32'd11);
        set_exp(20, 32'd12);
        set_exp(22, 32'd13);
        set_exp(23, 32'd14);
        set_exp(24, 32'hFFFFFFFB);
        set_exp(25, 32'hFFFFFFFD);
        set_exp(27, 32'd15);
        set_exp(29, 32'd16);
        set_exp(30, 32'd18);
        set_exp(31, 32'd17);
        check_regs;
        run_n(2);
        check_pc(32'd200);
        check_reg(4, 32'd19);

        $display("-------- backward branch --------");
        hold_reset_and_clear;
        uut.imem.ROM[0] = 32'h00000093; // addi x1, x0, 0
        uut.imem.ROM[1] = 32'h00108093; // addi x1, x1, 1
        uut.imem.ROM[2] = 32'h00300113; // addi x2, x0, 3
        uut.imem.ROM[3] = 32'hFE20CCE3; // blt  x1, x2, -8
        uut.imem.ROM[4] = 32'h00900193; // addi x3, x0, 9
        release_reset;
        check_pc(32'd0);
        run_n(11);
        check_pc(32'd20);
        clear_exp;
        set_exp(1, 32'd3);
        set_exp(2, 32'd3);
        set_exp(3, 32'd9);
        check_regs;

        $display("-------- jal and jalr --------");
        hold_reset_and_clear;
        uut.imem.ROM[0] = 32'h00C000EF; // jal  x1, 12
        uut.imem.ROM[1] = 32'h00700193; // addi x3, x0, 7
        uut.imem.ROM[2] = 32'h00C0006F; // jal  x0, 12
        uut.imem.ROM[3] = 32'h000082E7; // jalr x5, x1, 0
        uut.imem.ROM[4] = 32'h06300313; // addi x6, x0, 99
        uut.imem.ROM[5] = 32'h00300393; // addi x7, x0, 3
        release_reset;
        check_pc(32'd0);
        run_n(5);
        check_pc(32'd24);
        clear_exp;
        set_exp(1, 32'd4);
        set_exp(3, 32'd7);
        set_exp(5, 32'd16);
        set_exp(7, 32'd3);
        check_regs;

        $display("-------- jalr target alignment --------");
        hold_reset_and_clear;
        uut.imem.ROM[0] = 32'h00900093; // addi x1, x0, 9
        uut.imem.ROM[1] = 32'h00408167; // jalr x2, x1, 4   ; (9 + 4) with bit 0 cleared
        uut.imem.ROM[2] = 32'h06300193; // addi x3, x0, 99
        uut.imem.ROM[3] = 32'h01500213; // addi x4, x0, 21
        release_reset;
        check_pc(32'd0);
        run_n(2);
        check_pc(32'd12);
        check_reg(1, 32'd9);
        check_reg(2, 32'd8);
        run_n(1);
        check_pc(32'd16);
        clear_exp;
        set_exp(1, 32'd9);
        set_exp(2, 32'd8);
        set_exp(4, 32'd21);
        check_regs;

        $display("-------- x0 --------");
        hold_reset_and_clear;
        uut.imem.ROM[0] = 32'h07B00013; // addi x0, x0, 123
        uut.imem.ROM[1] = 32'h000000B3; // add  x1, x0, x0
        uut.imem.ROM[2] = 32'h00408113; // addi x2, x1, 4
        uut.rf.rf[0] = 32'hDEADBEEF;
        release_reset;
        check_pc(32'd0);
        run_straight(3);
        clear_exp;
        set_exp(0, 32'hDEADBEEF); // write to x0 is ignored
        set_exp(2, 32'd4);        // reads of x0 are zero
        check_regs;

        $display("----------------------------------------");
        $display("Passed: %0d", pass_count);
        $display("Failed: %0d", fail_count);
        if (fail_count == 0)
            $display("All tests passed.");
        else
            $display("Some tests failed.");
        $display("Simulation complete.");
        $finish;
    end

endmodule
