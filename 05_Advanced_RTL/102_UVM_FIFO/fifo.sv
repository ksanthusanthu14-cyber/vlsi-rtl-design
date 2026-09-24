module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 8
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  wr_en,
    input  logic                  rd_en,

    input  logic [DATA_WIDTH-1:0] wr_data,
    output logic [DATA_WIDTH-1:0] rd_data,

    output logic                  full,
    output logic                  empty
);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    integer wr_ptr;
    integer rd_ptr;
    integer count;

    always @(posedge clk) begin

        if (rst) begin

            wr_ptr  <= 0;
            rd_ptr  <= 0;
            count   <= 0;
            rd_data <= 0;

        end
        else begin

            // Write
            if (wr_en && !full) begin

                mem[wr_ptr] <= wr_data;

                if (wr_ptr == DEPTH-1)
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1;

            end


            // Read
            if (rd_en && !empty) begin

                rd_data <= mem[rd_ptr];

                if (rd_ptr == DEPTH-1)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1;

            end


            // Count update
            case ({wr_en && !full, rd_en && !empty})

                2'b10:
                    count <= count + 1;

                2'b01:
                    count <= count - 1;

                default:
                    count <= count;

            endcase

        end

    end


    always @(*) begin

        if (count == 0)
            empty = 1;
        else
            empty = 0;

        if (count == DEPTH)
            full = 1;
        else
            full = 0;

    end

endmodule