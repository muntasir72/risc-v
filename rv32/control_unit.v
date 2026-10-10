
module control_unit (
    input wire [6:0] opcode,
    input wire [2:0] func3,
    input wire [6:0] func7,
    output reg reg_write,
    output reg [2:0] alu_control
);

    always @(*) begin
        // Safe defaults: do not write for invalid instructions
        reg_write = 1'b0;
        alu_control = 3'b111;

        if (opcode == 7'b0110011) begin
            case (func3)

                // ADD and SUB
                3'b000: begin
                    if (func7 == 7'b0000000) begin
                        alu_control = 3'b000; // ADD
                        reg_write = 1'b1;
                    end
                    else if (func7 == 7'b0100000) begin
                        alu_control = 3'b001; // SUB
                        reg_write = 1'b1;
                    end
                end

                // SLT
                3'b010: begin
                    if (func7 == 7'b0000000) begin
                        alu_control = 3'b101;
                        reg_write = 1'b1;
                    end
                end

                // OR
                3'b110: begin
                    if (func7 == 7'b0000000) begin
                        alu_control = 3'b011;
                        reg_write = 1'b1;
                    end
                end

                // AND
                3'b111: begin
                    if (func7 == 7'b0000000) begin
                        alu_control = 3'b010;
                        reg_write = 1'b1;
                    end
                end

                default: begin
                    // Keep safe defaults
                end
            endcase
        end
    end

endmodule
