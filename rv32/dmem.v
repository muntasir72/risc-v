module dmem (
    input wire clk,
    input wire mem_write,
    input wire [31:0] addr,
    input wire [31:0] write_data,
    output wire [31:0] read_data
);

    reg [31:0] RAM [63:0]; // 64 word memory block

    assign read_data = RAM[addr[7:2]];

    always@(posedge clk) begin
        if(mem_write) begin
            RAM[addr[7:2]] <= write_data;
        end 
    end

endmodule