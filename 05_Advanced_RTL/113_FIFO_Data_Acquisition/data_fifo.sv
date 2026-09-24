`timescale 1ns/1ps

module data_fifo #(
    parameter integer DATA_WIDTH = 8,
    parameter integer DEPTH = 8
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,

    input  logic                  rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,

    output logic                  full,
    output logic                  empty,

    output logic [$clog2(DEPTH+1)-1:0] count,

    output logic                  overflow,
    output logic                  underflow
);

    localparam integer PTR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;


    assign full  = (count == DEPTH);
    assign empty = (count == 0);


    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            wr_ptr    <= '0;
            rd_ptr    <= '0;
            rd_data   <= '0;
            count     <= '0;
            overflow  <= 1'b0;
            underflow <= 1'b0;

        end

        else begin

            // Default: status flags are one-cycle events
            overflow  <= 1'b0;
            underflow <= 1'b0;


            // ====================================================
            // WRITE
            // ====================================================

            if (wr_en) begin

                if (!full) begin

                    mem[wr_ptr] <= wr_data;

                    if (wr_ptr == DEPTH-1)
                        wr_ptr <= '0;
                    else
                        wr_ptr <= wr_ptr + 1'b1;

                end
                else begin

                    overflow <= 1'b1;

                end

            end


            // ====================================================
            // READ
            // ====================================================

            if (rd_en) begin

                if (!empty) begin

                    rd_data <= mem[rd_ptr];

                    if (rd_ptr == DEPTH-1)
                        rd_ptr <= '0;
                    else
                        rd_ptr <= rd_ptr + 1'b1;

                end
                else begin

                    underflow <= 1'b1;

                end

            end


            // ====================================================
            // COUNT
            // ====================================================

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