`timescale 1ns/1ps

module apb_slave #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 8
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  psel,
    input  logic                  penable,
    input  logic                  pwrite,
    input  logic [ADDR_WIDTH-1:0] paddr,
    input  logic [DATA_WIDTH-1:0] pwdata,

    // Verification-only error injection
    input  logic                  error_inject,

    output logic [DATA_WIDTH-1:0] prdata,
    output logic                  pready,
    output logic                  pslverr
);

    // ============================================================
    // APB MEMORY
    // ============================================================

    logic [DATA_WIDTH-1:0] mem [0:255];

    integer wait_count;
    integer i;

    // ============================================================
    // APB SLAVE
    //
    // Address bit 7:
    //
    // 0 -> no wait state
    // 1 -> one wait state
    //
    // F0-F7:
    //
    // natural invalid-address error
    //
    // error_inject:
    //
    // verification error injection
    // ============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            prdata     <= '0;
            pready     <= 1'b0;
            pslverr    <= 1'b0;
            wait_count <= 0;

            // ----------------------------------------------------
            // Initialize APB memory
            // ----------------------------------------------------

            for (i = 0; i < 256; i = i + 1)
                mem[i] <= '0;

        end

        else begin

            // ----------------------------------------------------
            // Default outputs
            // ----------------------------------------------------

            pready  <= 1'b0;
            pslverr <= 1'b0;

            // ====================================================
            // APB ACCESS PHASE
            // ====================================================

            if (psel && penable) begin

                // =================================================
                // WAIT-STATE ACCESS
                // =================================================

                if (paddr[7]) begin

                    // ------------------------------------------------
                    // First access cycle -> wait
                    // ------------------------------------------------

                    if (wait_count == 0) begin

                        wait_count <= 1;

                    end

                    // ------------------------------------------------
                    // Second access cycle -> complete
                    // ------------------------------------------------

                    else begin

                        wait_count <= 0;

                        pready <= 1'b1;

                        // --------------------------------------------
                        // ERROR
                        // --------------------------------------------

                        if (error_inject ||
                            ((paddr >= 8'hF0) &&
                             (paddr <= 8'hF7))) begin

                            pslverr <= 1'b1;

                        end

                        // --------------------------------------------
                        // READ
                        // --------------------------------------------

                        if (!pwrite) begin

                            prdata <= mem[paddr];

                        end

                        // --------------------------------------------
                        // WRITE
                        //
                        // Don't modify memory when the transaction
                        // has an error.
                        // --------------------------------------------

                        else if (!error_inject &&
                                 !((paddr >= 8'hF0) &&
                                   (paddr <= 8'hF7))) begin

                            mem[paddr] <= pwdata;

                        end

                    end

                end

                // =================================================
                // NO-WAIT ACCESS
                // =================================================

                else begin

                    pready <= 1'b1;

                    // --------------------------------------------
                    // ERROR
                    // --------------------------------------------

                    if (error_inject ||
                        ((paddr >= 8'hF0) &&
                         (paddr <= 8'hF7))) begin

                        pslverr <= 1'b1;

                    end

                    // --------------------------------------------
                    // READ
                    // --------------------------------------------

                    if (!pwrite) begin

                        prdata <= mem[paddr];

                    end

                    // --------------------------------------------
                    // WRITE
                    //
                    // Don't modify memory on an error.
                    // --------------------------------------------

                    else if (!error_inject &&
                             !((paddr >= 8'hF0) &&
                               (paddr <= 8'hF7))) begin

                        mem[paddr] <= pwdata;

                    end

                end

            end

            // ====================================================
            // IDLE / SETUP
            // ====================================================

            else begin

                wait_count <= 0;

            end

        end

    end

endmodule