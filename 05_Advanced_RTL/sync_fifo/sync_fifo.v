module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH      = 16
)(
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  wr_en,
    input  wire                  rd_en,

    input  wire [DATA_WIDTH-1:0] din,
    output reg  [DATA_WIDTH-1:0] dout,

    output wire                  full,
    output wire                  empty
);

    // Address width
    localparam ADDR_WIDTH = $clog2(DEPTH);

    // FIFO memory
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Read and write pointers
    reg [ADDR_WIDTH-1:0] wr_ptr;
    reg [ADDR_WIDTH-1:0] rd_ptr;

    // Number of stored elements
    reg [ADDR_WIDTH:0] count;

    // Status flags
    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    always @(posedge clk) begin

        if (rst) begin

            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
            dout   <= 0;

        end

        else begin

            // Write operation
            if (wr_en && !full) begin
                mem[wr_ptr] <= din;
                wr_ptr <= wr_ptr + 1'b1;
            end

            // Read operation
            if (rd_en && !empty) begin
                dout <= mem[rd_ptr];
                rd_ptr <= rd_ptr + 1'b1;
            end

            // Count update
            case ({wr_en && !full, rd_en && !empty})

                2'b10:
                    count <= count + 1'b1;

                2'b01:
                    count <= count - 1'b1;

                default:
                    count <= count;

            endcase

        end

    end

endmodule