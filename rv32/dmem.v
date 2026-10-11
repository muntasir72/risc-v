module dmem (
    input wire clk,
    input wire mem_write,
    input wire [2:0] func3,  // determines memory size
    input wire [31:0] addr,
    input wire [31:0] write_data,
    output reg [31:0] read_data
);

    reg [31:0] RAM [63:0];
    
    // wire to read the full 32-bit word at the address
    wire [31:0] word = RAM[addr[7:2]];

    // read logic (load instructions)

    always @(*) begin
        case (func3)
            3'b000: // LB
                case (addr[1:0])
                    2'b00: read_data = {{24{word[7]}}, word[7:0]};
                    2'b01: read_data = {{24{word[15]}}, word[15:8]};
                    2'b10: read_data = {{24{word[23]}}, word[23:16]};
                    2'b11: read_data = {{24{word[31]}}, word[31:24]};
                endcase
            3'b001: // LH
                case (addr[1]) // Bit 1 determines upper or lower halfword
                    1'b0: read_data = {{16{word[15]}}, word[15:0]};
                    1'b1: read_data = {{16{word[31]}}, word[31:16]};
                endcase
            3'b010: // LW
                read_data = word;
            3'b100: // LBU
                case (addr[1:0])
                    2'b00: read_data = {24'b0, word[7:0]};
                    2'b01: read_data = {24'b0, word[15:8]};
                    2'b10: read_data = {24'b0, word[23:16]};
                    2'b11: read_data = {24'b0, word[31:24]};
                endcase
            3'b101: // LHU
                case (addr[1])
                    1'b0: read_data = {16'b0, word[15:0]};
                    1'b1: read_data = {16'b0, word[31:16]};
                endcase
            default: read_data = 32'b0;
        endcase
    end

    // write logic (store instructions)

    always @(posedge clk) begin
        if (mem_write) begin
            case (func3)
                3'b000: // SB
                    case (addr[1:0])
                        2'b00: RAM[addr[7:2]][7:0]   <= write_data[7:0];
                        2'b01: RAM[addr[7:2]][15:8]  <= write_data[7:0];
                        2'b10: RAM[addr[7:2]][23:16] <= write_data[7:0];
                        2'b11: RAM[addr[7:2]][31:24] <= write_data[7:0];
                    endcase
                3'b001: // SH
                    case (addr[1])
                        1'b0: RAM[addr[7:2]][15:0]  <= write_data[15:0];
                        1'b1: RAM[addr[7:2]][31:16] <= write_data[15:0];
                    endcase
                3'b010: // SW
                    RAM[addr[7:2]] <= write_data;
            endcase
        end
    end

endmodule