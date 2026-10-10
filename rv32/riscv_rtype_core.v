module riscv_rtype_core (
    input wire clk,
    input wire reset
);
    wire [31:0] pc, instr;
    wire [31:0] rs1_data, rs2_data, alu_result;
    wire reg_write;
    wire [2:0] alu_control;

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

    // 3. Control Unit
    control_unit ctrl (
        .opcode(instr[6:0]), 
        .func3(instr[14:12]), 
        .func7(instr[31:25]),
        .reg_write(reg_write), 
        .alu_control(alu_control)
    );

    // 4. Register File 
    regfile rf (
        .clk(clk), 
        .reg_write(reg_write), 
        .rs1(instr[19:15]),    // Extracting Source Register 1
        .rs2(instr[24:20]),    // Extracting Source Register 2
        .rd(instr[11:7]),      // Extracting Destination Register
        .write_data(alu_result), 
        .rs1_data(rs1_data), 
        .rs2_data(rs2_data)
    );

    // 5. ALU 
    alu alu_inst (
        .src_a(rs1_data), 
        .src_b(rs2_data), 
        .alu_control(alu_control), 
        .alu_result(alu_result)
    );

endmodule