module control_unit (
    input wire [6:0] opcode,
    input wire [2:0] func3,
    input wire [6:0] func7,
    output reg reg_write, alu_src, mem_write, branch, jump,
    output reg [1:0] result_src,
    output reg [1:0] alu_src_a,
    output reg [5:0] alu_control
);

    always @(*) begin
        // Safe defaults
        reg_write = 1'b0;
        alu_src = 1'b0;
        alu_control = 6'b111111;
        mem_write = 1'b0;
        result_src = 2'b00;
        branch = 1'b0;
        jump = 1'b0;

        // R-Type or I-Type
        if (opcode == 7'b0110011 || opcode == 7'b0010011) begin
            
            // R and I types write to the register file
            reg_write = 1'b1;
            
            // I-Type (0010011) uses immediate (1), R-Type uses register (0)
            alu_src = (opcode == 7'b0010011); 

            // I-type and R-type instructions use the same func3 for the instructions (except subi)
            case (func3)
                // do SUB only if it's an R-Type AND func7 bit 5 is 1, otherwise ADD/ADDI.
                3'b000: alu_control = (opcode == 7'b0110011 && func7[5]) ? 6'b000001 : 6'b000000; 
                
                3'b001: alu_control = 6'b000010; // SLL / SLLI
                3'b010: alu_control = 6'b000011; // SLT / SLTI
                3'b011: alu_control = 6'b000100; // SLTU / SLTIU
                3'b100: alu_control = 6'b000101; // XOR / XORI
                
                // (SRA/SRAI) / (SRL/SRLI)
                3'b101: alu_control = (func7[5]) ? 6'b000111 : 6'b000110; 
                
                3'b110: alu_control = 6'b001000; // OR / ORI
                3'b111: alu_control = 6'b001001; // AND / ANDI
            endcase
        end
        // Load instruction
        else if (opcode == 7'b0000011) begin
            alu_src = 1'b1;      // use immediate for address
            reg_write = 1'b1;    // save to register
            result_src = 2'b01;   // save from MEMORY, not ALU
            alu_control = 6'b000000; // ADD (rs1 + imm)
        end
        // S-type instruction
        else if (opcode == 7'b0100011) begin
            alu_src = 1'b1;      // use immediate for address
            mem_write = 1'b1;    // enable memory writing
            alu_control = 6'b000000; // ADD (rs1 + imm)
        end
        // Branch (BEQ, BNE, BLT, BGE, BLTU, BGEU)
        else if (opcode == 7'b1100011) begin
            branch = 1'b1; 
        end
        // JAL (Jump and Link)
        else if (opcode == 7'b1101111) begin
            jump = 1'b1; reg_write = 1'b1; result_src = 2'b10; // Save PC+4 to register
        end
        // JALR (Jump and Link Register)
        else if (opcode == 7'b1100111) begin
            jump = 1'b1; reg_write = 1'b1; result_src = 2'b10; // Save PC+4 to register
            alu_src = 1'b1; alu_control = 6'b000000;           // ALU computes (rs1 + imm)
        end
        // LUI (Load Upper Immediate)
        else if (opcode == 7'b0110111) begin
            alu_src_a = 2'b10;       // Route 0 into ALU src_a
            alu_src = 1'b1;          // Route imm into ALU src_b
            reg_write = 1'b1;        // Save result
            alu_control = 6'b000000; // ALU calculates (0 + imm)
        end
        // AUIPC
        else if (opcode == 7'b0010111) begin
            alu_src_a = 2'b01;       // Route PC into ALU src_a
            alu_src = 1'b1;          // Route imm into ALU src_b
            reg_write = 1'b1;        // Save result
            alu_control = 6'b000000; // ALU calculates (PC + imm)
        end
    end

endmodule