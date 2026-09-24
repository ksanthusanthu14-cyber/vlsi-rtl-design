`timescale 1ns/1ps

module fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input  logic                 clk,
    input  logic                 rst,

    input  logic                 wr_en,
    input  logic [DATA_WIDTH-1:0] wr_data,

    input  logic                 rd_en,
    output logic [DATA_WIDTH-1:0] rd_data,

    output logic                 full,
    output logic                 empty,

    output logic [$clog2(DEPTH+1)-1:0] count
);

    localparam int PTR_WIDTH = $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;

    logic write_allowed;
    logic read_allowed;


    assign full  = (count == DEPTH);
    assign empty = (count == 0);

    assign write_allowed = wr_en && !full;
    assign read_allowed  = rd_en && !empty;


    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            wr_ptr  <= '0;
            rd_ptr  <= '0;
            count   <= '0;
            rd_data <= '0;

        end

        else begin

            //========================================
            // WRITE
            //========================================

            if (write_allowed) begin

                mem[wr_ptr] <= wr_data;

                if (wr_ptr == DEPTH-1)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;

            end


            //========================================
            // READ
            //========================================

            if (read_allowed) begin

                rd_data <= mem[rd_ptr];

                if (rd_ptr == DEPTH-1)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;

            end


            //========================================
            // COUNT
            //========================================

            case ({write_allowed, read_allowed})

                2'b10:
                    count <= count + 1'b1;

                2'b01:
                    count <= count - 1'b1;

                2'b11:
                    count <= count;

                default:
                    count <= count;

            endcase

        end

    end

endmodule