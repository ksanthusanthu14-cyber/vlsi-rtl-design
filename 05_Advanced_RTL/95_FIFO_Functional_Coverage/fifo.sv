`timescale 1ns/1ps

module fifo #(
    parameter WIDTH = 8,
    parameter DEPTH = 8
)(
    input  logic             clk,
    input  logic             rst,

    input  logic             wr_en,
    input  logic             rd_en,

    input  logic [WIDTH-1:0] din,
    output logic [WIDTH-1:0] dout,

    output logic             full,
    output logic             empty,

    output logic [$clog2(DEPTH+1)-1:0] count
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    logic [WIDTH-1:0] mem [0:DEPTH-1];

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;


    //============================================================
    // STATUS
    //============================================================

    always_comb begin

        empty = (count == 0);

        full  = (count == DEPTH);

    end


    //============================================================
    // FIFO
    //============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            wr_ptr <= 0;
            rd_ptr <= 0;

            count <= 0;

            dout <= 0;

        end

        else begin

            //====================================================
            // WRITE
            //====================================================

            if (wr_en && !full) begin

                mem[wr_ptr] <= din;

                if (wr_ptr == DEPTH-1)
                    wr_ptr <= 0;
                else
                    wr_ptr <= wr_ptr + 1'b1;

            end


            //====================================================
            // READ
            //====================================================

            if (rd_en && !empty) begin

                dout <= mem[rd_ptr];

                if (rd_ptr == DEPTH-1)
                    rd_ptr <= 0;
                else
                    rd_ptr <= rd_ptr + 1'b1;

            end


            //====================================================
            // COUNT
            //====================================================

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