`timescale 1ns/1ps

module apb_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input  logic                  pclk,
    input  logic                  presetn,

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

    integer i;

    // Wait-state counter
    integer wait_count;

    // ============================================================
    // APB SLAVE
    // ============================================================

    always @(posedge pclk) begin

        if (!presetn) begin

            prdata    <= 0;
            pready    <= 1'b0;
            pslverr   <= 1'b0;
            wait_count <= 0;

            for (i = 0; i < 256; i = i + 1)
                mem[i] <= 0;

        end

        else begin

            pready  <= 1'b0;
            pslverr <= 1'b0;

            // ----------------------------------------------------
            // ACCESS PHASE
            // ----------------------------------------------------

            if (psel && penable) begin

                // Address ending in 11 is treated as an error
                if (paddr[1:0] == 2'b11) begin

                    pready  <= 1'b1;
                    pslverr <= 1'b1;

                end

                else begin

                    // Introduce deterministic wait states
                    if (wait_count < 2) begin

                        wait_count <= wait_count + 1;

                    end

                    else begin

                        wait_count <= 0;

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

            else begin

                wait_count <= 0;

            end

        end

    end

endmodule