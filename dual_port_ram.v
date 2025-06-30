// File: dual_port_ram_cdc.v
// CDC-Safe Dual-Port RAM with Handshake-Based Arbitration Logic and Read-After-Write Handling

module dual_port_ram_cdc #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 1 << ADDR_WIDTH
)(
    input wire clk_a,
    input wire rst_a,
    input wire we_a,
    input wire [ADDR_WIDTH-1:0] addr_a,
    input wire [DATA_WIDTH-1:0] din_a,
    output reg [DATA_WIDTH-1:0] dout_a,

    input wire clk_b,
    input wire rst_b,
    input wire we_b,
    input wire [ADDR_WIDTH-1:0] addr_b,
    input wire [DATA_WIDTH-1:0] din_b,
    output reg [DATA_WIDTH-1:0] dout_b
);

    // Shared memory
    (* ram_style = "distributed" *) reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write request from Port B to Port A domain using handshake
    reg [DATA_WIDTH-1:0] din_b_sync;
    reg [ADDR_WIDTH-1:0] addr_b_sync;
    reg we_b_req, we_b_ack;
    reg we_b_sync1, we_b_sync2;

    // FSM in clk_b to initiate handshake and RAW-safe read
    always @(posedge clk_b or posedge rst_b) begin
        if (rst_b) begin
            we_b_req <= 0;
            dout_b <= 0;
        end else begin
            if (we_b && !we_b_req) begin
                din_b_sync <= din_b;
                addr_b_sync <= addr_b;
                we_b_req <= 1;
                dout_b <= din_b; // Write forwarding
            end else if (we_b_ack) begin
                we_b_req <= 0;
                dout_b <= din_b_sync; // RAW-safe echo after ack
            end else begin
                dout_b <= mem[addr_b];
            end
        end
    end

    // Synchronize request signal to clk_a domain
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            we_b_sync1 <= 0;
            we_b_sync2 <= 0;
        end else begin
            we_b_sync1 <= we_b_req;
            we_b_sync2 <= we_b_sync1;
        end
    end

    // Acknowledge logic from clk_a domain
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            we_b_ack <= 0;
        end else begin
            we_b_ack <= we_b_sync2;
        end
    end

    // Port A logic with handshake-based arbitration and RAW
    always @(posedge clk_a or posedge rst_a) begin
        if (rst_a) begin
            dout_a <= 0;
        end else begin
            if (we_a) begin
                mem[addr_a] <= din_a;
                dout_a <= din_a; // Write forwarding
            end else if (we_b_sync2 && !(we_a && (addr_a == addr_b_sync))) begin
                mem[addr_b_sync] <= din_b_sync;
            end
            dout_a <= mem[addr_a];
        end
    end

endmodule
