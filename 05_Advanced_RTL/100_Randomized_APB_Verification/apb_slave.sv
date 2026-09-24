module apb_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  psel,
    input  logic                  penable,
    input  logic                  pwrite,

    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic [DATA_WIDTH-1:0] pwdata,

    output logic [DATA_WIDTH-1:0] prdata,
    output logic                  pready,
    output logic                  pslverr
);

    logic [DATA_WIDTH-1:0] mem [0:255];

    integer wait_count;

    always_ff @(posedge clk) begin

        if (rst) begin

            prdata     <= '0;
            pready     <= 1'b0;
            pslverr    <= 1'b0;
            wait_count <= 0;

            for (integer i = 0; i < 256; i = i + 1)
                mem[i] <= '0;
        end

        else begin

            pready  <= 1'b0;
            pslverr <= 1'b0;

            /*
             * APB SETUP phase.
             * Randomly choose 0-3 wait cycles for the
             * following ACCESS phase.
             */
            if (psel && !penable) begin

                wait_count <= $urandom_range(0, 3);

            end

            /*
             * APB ACCESS phase.
             */
            else if (psel && penable) begin

                if (wait_count > 0) begin

                    wait_count <= wait_count - 1;

                end

                else begin

                    /*
                     * Addresses whose lower two bits are 11
                     * generate an APB slave error.
                     */
                    if (paddr[1:0] == 2'b11) begin

                        pslverr <= 1'b1;
                        pready  <= 1'b1;

                    end

                    else begin

                        pready <= 1'b1;

                        if (pwrite) begin

                            mem[paddr] <= pwdata;

                        end

                        else begin

                            prdata <= mem[paddr];

                        end

                    end

                end

            end

        end

    end

endmodule