module control_unit (
    input wire [6:0] opcode,        // our opcode
    input wire [2:0] func3,        // func3
    input wire [6:0 ]func7,         // func7
    output reg reg_write,
    output reg [2:0] alu_control
);
    always @(*) begin
        // 7'b0110011 is the opcode for ALL standard R-type instructions
        if (opcode == 7'b0110011) begin
            reg_write = 1; 
            
            case(func3)
                3'b000:
                begin
                    if (func7 == 7'b0100000)
                        alu_control = 3'b001; // SUB
                    else if (func7 == 7'b0000000)
                        alu_control = 3'b000; // ADD
                    else
                        alu_control = 3'b111; // Invalid
                end
                3'b010: alu_control = (func7 == 7'b0000000) ? 3'b101 : 3'b111; // SLT

                3'b110: alu_control = (func7 == 7'b0000000) ? 3'b011 : 3'b111; // OR

                3'b111: alu_control = (func7 == 7'b0000000) ? 3'b010 : 3'b111; // AND
                default: alu_control = 3'b111; 
            endcase
        end 
        else begin
            reg_write = 0;
            alu_control = 3'b111;
        end
    end
endmodule