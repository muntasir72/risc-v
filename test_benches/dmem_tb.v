`timescale 1ns/1ns
module dmem_tb;
    reg clk;
    reg mem_write;
    reg [2:0] func3;
    reg [31:0] addr, write_data;
    wire [31:0] read_data;

    dmem uut (
        .clk(clk),
        .mem_write(mem_write),
        .func3(func3),
        .addr(addr),
        .write_data(write_data),
        .read_data(read_data)
    );

    always #5 clk = ~clk;

    task store;
        input [2:0] op;
        input [31:0] address, data;
        begin
            @(negedge clk);
            func3 = op;
            addr = address;
            write_data = data;
            mem_write = 1'b1;
            @(posedge clk);
            #1;
            mem_write = 1'b0;
        end
    endtask

    task check_load;
        input [2:0] op;
        input [31:0] address, expected;
        input [160*8-1:0] test_name;
        begin
            func3 = op;
            addr = address;
            #1;
            if (read_data !== expected)
                $fatal(1, "dmem failed (%0s): func3=%b addr=%h expected=%h got=%h",
                       test_name, op, address, expected, read_data);
        end
    endtask

    initial begin
        clk = 0;
        mem_write = 0;
        func3 = 3'b010;
        addr = 0;
        write_data = 0;

        // Initialize word at address 0, then verify word and byte/halfword loads.
        store(3'b010, 32'h00000000, 32'h80FF7F01);
        check_load(3'b010, 32'h00000000, 32'h80FF7F01, "LW");
        check_load(3'b000, 32'h00000000, 32'h00000001, "LB byte 0");
        check_load(3'b000, 32'h00000001, 32'h0000007F, "LB byte 1");
        check_load(3'b000, 32'h00000002, 32'hFFFFFFFF, "LB signed byte 2");
        check_load(3'b000, 32'h00000003, 32'hFFFFFF80, "LB signed byte 3");
        check_load(3'b100, 32'h00000002, 32'h000000FF, "LBU byte 2");
        check_load(3'b100, 32'h00000003, 32'h00000080, "LBU byte 3");
        check_load(3'b001, 32'h00000000, 32'h00007F01, "LH lower half");
        check_load(3'b001, 32'h00000002, 32'hFFFF80FF, "LH signed upper half");
        check_load(3'b101, 32'h00000002, 32'h000080FF, "LHU upper half");

        // Byte store into byte lane 1: 0x80FF7F01 -> 0x80FFAA01.
        store(3'b000, 32'h00000001, 32'h000000AA);
        check_load(3'b010, 32'h00000000, 32'h80FFAA01, "SB byte lane 1");

        // Halfword store into upper half: 0x80FFAA01 -> 0x1234AA01.
        store(3'b001, 32'h00000002, 32'h00001234);
        check_load(3'b010, 32'h00000000, 32'h1234AA01, "SH upper half");

        // Verify mem_write=0 prevents a store.
        @(negedge clk);
        addr = 0;
        func3 = 3'b010;
        write_data = 32'hDEADBEEF;
        mem_write = 0;
        @(posedge clk); #1;
        check_load(3'b010, 32'h00000000, 32'h1234AA01, "write disabled");

        $display("dmem_tb: all checks passed");
        $finish;
    end
endmodule
