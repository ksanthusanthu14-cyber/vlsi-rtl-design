`timescale 1ns/1ps

module parameterized_fifo #(
    parameter int DATA_WIDTH = 8,
    parameter int DEPTH      = 16
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  wr_en,
    input  logic                  rd_en,

    input  logic [DATA_WIDTH-1:0] data_in,
    output logic [DATA_WIDTH-1:0] data_out,

    output logic                  full,
    output logic                  empty,

    output logic [$clog2(DEPTH+1)-1:0] count
);

    localparam int PTR_WIDTH =
        (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;

    logic write_allowed;
    logic read_allowed;


    //==================================================
    // STATUS
    //==================================================

    always_comb begin

        empty = (count == 0);
        full  = (count == DEPTH);

    end


    //==================================================
    // OPERATION QUALIFICATION
    //==================================================

    always_comb begin

        write_allowed = wr_en && !full;
        read_allowed  = rd_en && !empty;

    end


    //==================================================
    // FIFO
    //==================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            wr_ptr   <= '0;
            rd_ptr   <= '0;
            count    <= '0;
            data_out <= '0;

        end

        else begin

            //==========================================
            // WRITE
            //==========================================

            if (write_allowed) begin

                mem[wr_ptr] <= data_in;

                if (wr_ptr == DEPTH-1)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;

            end


            //==========================================
            // READ
            //==========================================

            if (read_allowed) begin

                data_out <= mem[rd_ptr];

                if (rd_ptr == DEPTH-1)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;

            end


            //==========================================
            // OCCUPANCY
            //==========================================

            case ({write_allowed, read_allowed})

                2'b10: begin
                    count <= count + 1'b1;
                end

                2'b01: begin
                    count <= count - 1'b1;
                end

                2'b11: begin
                    count <= count;
                end

                default: begin
                    count <= count;
                end

            endcase

        end

    end

endmodule