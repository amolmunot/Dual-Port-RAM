`timescale 1ns/1ps

module tb_dual_port_ram_cdc;

    parameter DATA_WIDTH = 8;
    parameter ADDR_WIDTH = 4;
    parameter DEPTH = 1 << ADDR_WIDTH;

    reg clk_a = 0;
    reg rst_a = 1;
    reg we_a = 0;
    reg [ADDR_WIDTH-1:0] addr_a = 0;
    reg [DATA_WIDTH-1:0] din_a = 0;
    wire [DATA_WIDTH-1:0] dout_a;

    reg clk_b = 0;
    reg rst_b = 1;
    reg we_b = 0;
    reg [ADDR_WIDTH-1:0] addr_b = 0;
    reg [DATA_WIDTH-1:0] din_b = 0;
    wire [DATA_WIDTH-1:0] dout_b;

    // DUT instantiation
    dual_port_ram_cdc #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) dut (
        .clk_a(clk_a),
        .rst_a(rst_a),
        .we_a(we_a),
        .addr_a(addr_a),
        .din_a(din_a),
        .dout_a(dout_a),
        .clk_b(clk_b),
        .rst_b(rst_b),
        .we_b(we_b),
        .addr_b(addr_b),
        .din_b(din_b),
        .dout_b(dout_b)
    );

    // Clock generation
    always #5 clk_a = ~clk_a;  // 100MHz
    always #7 clk_b = ~clk_b;  // ~71.4MHz

    // Stimulus
    initial begin
        $dumpfile("waveform.vcd");
        $dumpvars(0, tb_dual_port_ram_cdc);

        // Initial Reset
        #10;
        rst_a = 0;
        rst_b = 0;

        // PORT A writes data
        @(posedge clk_a);
        addr_a = 4'h1; din_a = 8'hAA; we_a = 1;
        @(posedge clk_a);
        we_a = 0;

        @(posedge clk_a);
        addr_a = 4'h2; din_a = 8'hBB; we_a = 1;
        @(posedge clk_a);
        we_a = 0;

        // PORT B writes to a different address (no conflict)
        @(posedge clk_b);
        addr_b = 4'h3; din_b = 8'hCC; we_b = 1;
        @(posedge clk_b);
        we_b = 0;

        // PORT B writes to a conflicting address (should get ignored if A is active)
        @(posedge clk_b);
        addr_b = 4'h1; din_b = 8'hDD; we_b = 1;
        @(posedge clk_b);
        we_b = 0;

        // Read from PORT A
        repeat(3) @(posedge clk_a);
        addr_a = 4'h1; we_a = 0;

        @(posedge clk_a);
        addr_a = 4'h2;

        @(posedge clk_a);
        addr_a = 4'h3;

        // Read from PORT B
        repeat(3) @(posedge clk_b);
        addr_b = 4'h3;

        @(posedge clk_b);
        addr_b = 4'h1;

        // Finish
        #100;
        $finish;
    end

endmodule
