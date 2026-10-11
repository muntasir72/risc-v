module riscv_rtype_core (
    input wire clk,
    input wire reset
);
    wire [31:0] pc, instr;
    wire [31:0] rs1_data, rs2_data, alu_result;
    wire [31:0] imm, src_b;

    wire reg_write, alu_src, mem_write, result_src;
    wire [5:0] alu_control;
    wire [31:0] read_data, writeback_data;

    // 1. PC Logic
    pc_reg pcreg (
        .clk(clk), 
        .reset(reset), 
        .pc_next(pc + 4), 
        .pc(pc)
    );

    // 2. Fetch Instruction
    imem imem (
        .pc(pc), 
        .instr(instr)
    );

    // Immediate Generator
    immgen ig (
        .instr(instr),
        .imm(imm)
    );

    // 3. Control Unit
    control_unit ctrl (
        .opcode(instr[6:0]), 
        .func3(instr[14:12]), 
        .func7(instr[31:25]),
        .reg_write(reg_write), 
        .alu_control(alu_control),
        .alu_src(alu_src),
        .mem_write(mem_write),
        .result_src(result_src)
    );

    // 4. Register File 
    regfile rf (
        .clk(clk), 
        .reg_write(reg_write), 
        .rs1(instr[19:15]),    // Extracting Source Register 1
        .rs2(instr[24:20]),    // Extracting Source Register 2
        .rd(instr[11:7]),      // Extracting Destination Register
        .write_data(writeback_data), 
        .rs1_data(rs1_data), 
        .rs2_data(rs2_data)
    );

    assign src_b = (alu_src) ? imm : rs2_data;

    // 5. ALU 
    alu alu_inst (
        .src_a(rs1_data), 
        .src_b(src_b), 
        .alu_control(alu_control), 
        .alu_result(alu_result)
    );

    // Data Memory
    dmem dm (
        .clk(clk),
        .mem_write(mem_write),
        .addr(alu_result),
        .write_data(rs2_data),
        .read_data(read_data),
        .func3(instr[14:12])
    );

    assign writeback_data = (result_src) ? read_data : alu_result;

endmodule