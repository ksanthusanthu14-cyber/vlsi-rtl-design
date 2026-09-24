module synchronous_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 8
)(
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  write_en,
    input  wire                  read_en,

    input  wire [DATA_WIDTH-1:0] data_in,
    output reg  [DATA_WIDTH-1:0] data_out,

    output wire                  full,
    output wire                  empty
);

    localparam ADDR_WIDTH = $clog2(DEPTH);

    // FIFO memory
    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    // Read and write pointers
    reg [ADDR_WIDTH-1:0] write_ptr;
    reg [ADDR_WIDTH-1:0] read_ptr;

    // Number of stored elements
    reg [ADDR_WIDTH:0] count;

    // FIFO status
    assign empty = (count == 0);
    assign full  = (count == DEPTH);

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            write_ptr <= 0;
            read_ptr  <= 0;
            count     <= 0;
            data_out  <= 0;
        end

        else begin

            // Write operation
            if (write_en && !full) begin
                memory[write_ptr] <= data_in;
                write_ptr <= write_ptr + 1'b1;
            end

            // Read operation
            if (read_en && !empty) begin
                data_out <= memory[read_ptr];
                read_ptr <= read_ptr + 1'b1;
            end

            // Count update
            case ({write_en && !full, read_en && !empty})

                2'b10: begin
                    // Write only
                    count <= count + 1'b1;
                end

                2'b01: begin
                    // Read only
                    count <= count - 1'b1;
                end

                2'b11: begin
                    // Simultaneous read and write
                    count <= count;
                end

                default: begin
                    count <= count;
                end

            endcase

        end

    end

endmodule