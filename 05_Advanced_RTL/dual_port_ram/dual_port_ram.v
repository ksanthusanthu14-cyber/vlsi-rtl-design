module dual_port_ram #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 4
)(
    // Port A
    input  wire                    clk_a,
    input  wire                    we_a,
    input  wire [ADDR_WIDTH-1:0]   addr_a,
    input  wire [DATA_WIDTH-1:0]   data_in_a,
    output reg  [DATA_WIDTH-1:0]   data_out_a,

    // Port B
    input  wire                    clk_b,
    input  wire                    we_b,
    input  wire [ADDR_WIDTH-1:0]   addr_b,
    input  wire [DATA_WIDTH-1:0]   data_in_b,
    output reg  [DATA_WIDTH-1:0]   data_out_b
);

    // 2^ADDR_WIDTH memory locations
    reg [DATA_WIDTH-1:0] memory [0:(1<<ADDR_WIDTH)-1];

    // Port A
    always @(posedge clk_a) begin

        if (we_a)
            memory[addr_a] <= data_in_a;

        data_out_a <= memory[addr_a];

    end

    // Port B
    always @(posedge clk_b) begin

        if (we_b)
            memory[addr_b] <= data_in_b;

        data_out_b <= memory[addr_b];

    end

endmodule