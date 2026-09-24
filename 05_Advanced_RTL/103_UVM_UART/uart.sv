`timescale 1ns/1ps

module uart #(
    parameter CLK_PER_BIT = 4
)(
    input  logic       clk,
    input  logic       rst,

    // TX
    input  logic       tx_start,
    input  logic [7:0] tx_data,
    output logic       tx,
    output logic       tx_busy,
    output logic       tx_done,

    // RX
    input  logic       rx,
    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       rx_error
);

    // ============================================================
    // TRANSMITTER
    // ============================================================

    logic [7:0] tx_shift;
    integer tx_count;
    integer tx_bit;

    always @(posedge clk) begin

        if (rst) begin

            tx       <= 1'b1;
            tx_busy  <= 1'b0;
            tx_done  <= 1'b0;

            tx_shift <= 8'h00;
            tx_count <= 0;
            tx_bit   <= 0;

        end
        else begin

            tx_done <= 1'b0;

            // Start a new frame
            if (tx_start && !tx_busy) begin

                tx_shift <= tx_data;

                tx_count <= 0;
                tx_bit   <= 0;

                tx_busy <= 1'b1;

                // START BIT
                tx <= 1'b0;

            end

            else if (tx_busy) begin

                if (tx_count == CLK_PER_BIT-1) begin

                    tx_count <= 0;

                    // DATA BITS
                    if (tx_bit < 8) begin

                        tx <= tx_shift[tx_bit];

                        tx_bit <= tx_bit + 1;

                    end

                    // STOP BIT
                    else begin

                        tx <= 1'b1;

                        tx_busy <= 1'b0;

                        tx_done <= 1'b1;

                    end

                end
                else begin

                    tx_count <= tx_count + 1;
                end

            end

        end

    end


    // ============================================================
    // RECEIVER
    // ============================================================

    logic [7:0] rx_shift;

    integer rx_count;
    integer rx_bit;

    logic rx_busy;


    always @(posedge clk) begin

        if (rst) begin

            rx_data  <= 8'h00;
            rx_valid <= 1'b0;
            rx_error <= 1'b0;

            rx_shift <= 8'h00;

            rx_count <= 0;
            rx_bit   <= 0;

            rx_busy  <= 1'b0;

        end
        else begin

            // These are pulse signals
            rx_valid <= 1'b0;
            rx_error <= 1'b0;


            // ====================================================
            // IDLE / START DETECTION
            // ====================================================

            if (!rx_busy) begin

                if (rx == 1'b0) begin

                    rx_busy <= 1'b1;

                    rx_bit <= 0;

                    /*
                     * We detected the START bit.
                     *
                     * The first DATA bit is one and a half
                     * bit periods from the start-bit edge.
                     *
                     * For CLK_PER_BIT = 4:
                     *
                     *     1.5 × 4 = 6 clocks
                     *
                     * We therefore wait 5 additional clocks
                     * before sampling D0.
                     */

                    rx_count <= CLK_PER_BIT
                                + (CLK_PER_BIT / 2)
                                - 1;

                end

            end


            // ====================================================
            // RECEIVE FRAME
            // ====================================================

            else begin

                if (rx_count > 0) begin

                    rx_count <= rx_count - 1;

                end

                else begin

                    // ------------------------------------------------
                    // DATA BITS
                    // ------------------------------------------------

                    if (rx_bit < 8) begin

                        rx_shift[rx_bit] <= rx;

                        rx_bit <= rx_bit + 1;

                        // Wait exactly one bit period
                        // before sampling the next bit.

                        rx_count <= CLK_PER_BIT - 1;

                    end

                    // ------------------------------------------------
                    // STOP BIT
                    // ------------------------------------------------

                    else begin

                        if (rx != 1'b1)
                            rx_error <= 1'b1;

                        rx_data <= rx_shift;

                        rx_valid <= 1'b1;

                        rx_busy <= 1'b0;

                        rx_count <= 0;

                    end

                end

            end

        end

    end

endmodule