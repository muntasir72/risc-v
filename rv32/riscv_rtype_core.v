module riscv_rtype_core (
    input wire clk,
    input wire reset
);
    // Wires connecting all the parts together
    wire [31:0] pc, next_pc, pc_plus_4, pc_target;
    wire [31:0] instr;
    wire [31:0] rs1_data, rs2_data, imm, src_b;
    wire [31:0] alu_result, read_data, writeback_data;
    
    wire reg_write, alu_src, mem_write;
    wire branch, jump, br_taken, pc_src;
    wire [1:0] result_src;
    wire [5:0] alu_control;

    // STAGE 1: FETCH
    
    // Keep track of the current line of code
    pc_reg pcreg (
        .clk(clk), 
        .reset(reset), 
        .pc_next(next_pc), 
        .pc(pc)
    );

    // Calculate the next default line (current + 4)
    assign pc_plus_4 = pc + 4;

    // Read the actual instruction from memory
    imem imem (
        .pc(pc), 
        .instr(instr)
    );

    // STAGE 2: DECODE
    
    // flips switches based on the instruction type
    control_unit ctrl (
        .opcode(instr[6:0]), 
        .func3(instr[14:12]), 
        .func7(instr[31:25]),
        .reg_write(reg_write), 
        .alu_control(alu_control), 
        .alu_src(alu_src),
        .mem_write(mem_write), 
        .result_src(result_src),
        .branch(branch), 
        .jump(jump)
    );

    // Extracts any hardcoded numbers from the instruction
    immgen ig (
        .instr(instr), 
        .imm(imm)
    );

    // Reads the saved data from our registers (x0 to x31)
    regfile rf (
        .clk(clk), 
        .reg_write(reg_write), 
        .rs1(instr[19:15]), 
        .rs2(instr[24:20]), 
        .rd(instr[11:7]), 
        .write_data(writeback_data), 
        .rs1_data(rs1_data), 
        .rs2_data(rs2_data)
    );

    // STAGE 3: EXECUTE

    // Choose between a register value or a hardcoded number
    assign src_b = (alu_src) ? imm : rs2_data;

    // Perform AL operations
    alu alu_inst (
        .src_a(rs1_data), 
        .src_b(src_b), 
        .alu_control(alu_control), 
        .alu_result(alu_result)
    );

    // Checks if a branch condition is true (like if x == y)
    branch_comp bc (
        .rs1_data(rs1_data), 
        .rs2_data(rs2_data), 
        .func3(instr[14:12]), 
        .br_taken(br_taken)
    );

    // Calculates the memory address if we need to jump or branch
    assign pc_target = (instr[6:0] == 7'b1100111) ? {alu_result[31:1], 1'b0} : (pc + imm);

    // STAGE 4: MEMORY
    
    // Reads from or writes to the RAM (for variables and arrays)
    dmem dm (
        .clk(clk), 
        .mem_write(mem_write), 
        .func3(instr[14:12]),
        .addr(alu_result),
        .write_data(rs2_data), 
        .read_data(read_data)
    );

    // STAGE 5: WRITEBACK

    // Picks which answer to save: Math, Memory, or Return Address
    assign writeback_data = (result_src == 2'b00) ? alu_result : (result_src == 2'b01) ? read_data : pc_plus_4;

    // Decides whether to jump to a new line or just go to the next line
    assign pc_src = jump | (branch & br_taken);
    assign next_pc = (pc_src) ? pc_target : pc_plus_4;

endmodule