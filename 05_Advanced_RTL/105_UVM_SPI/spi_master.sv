`timescale 1ns/1ps

module spi_master #(
    parameter DATA_WIDTH = 8
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  start,
    input  logic [DATA_WIDTH-1:0] tx_data,

    output logic [DATA_WIDTH-1:0] rx_data,
    output logic                  busy,
    output logic                  done,

    output logic                  cs,
    output logic                  sclk,
    output logic                  mosi,

    input  logic                  miso
);

    logic [DATA_WIDTH-1:0] tx_shift;
    logic [DATA_WIDTH-1:0] rx_shift;

    integer bit_count;

    // =========================================================
    // SPI MASTER
    // SPI MODE 0
    //
    // CPOL = 0
    // CPHA = 0
    //
    // Data sampled on rising edge
    // Data changed on falling edge
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            tx_shift <= 0;
            rx_shift <= 0;

            rx_data <= 0;

            busy <= 1'b0;
            done <= 1'b0;

            cs   <= 1'b1;
            sclk <= 1'b0;
            mosi <= 1'b0;

            bit_count <= 0;

        end

        else begin

            // DONE is a one-clock pulse
            done <= 1'b0;

            // =================================================
            // IDLE
            // =================================================

            if (!busy) begin

                sclk <= 1'b0;
                cs   <= 1'b1;

                if (start) begin

                    busy <= 1'b1;
                    cs   <= 1'b0;

                    tx_shift <= tx_data;
                    rx_shift <= 0;

                    bit_count <= 0;

                    // First bit available before first rising edge
                    mosi <= tx_data[DATA_WIDTH-1];

                end

            end

            // =================================================
            // ACTIVE TRANSACTION
            // =================================================

            else begin

                // -------------------------------------------------
                // LOW -> HIGH
                // SPI sampling edge
                // -------------------------------------------------

                if (sclk == 1'b0) begin

                    sclk <= 1'b1;

                    // Sample MISO
                    rx_shift <= {
                        rx_shift[DATA_WIDTH-2:0],
                        miso
                    };

                    bit_count <= bit_count + 1;

                end

                // -------------------------------------------------
                // HIGH -> LOW
                // SPI data-change edge
                // -------------------------------------------------

                else begin

                    sclk <= 1'b0;

                    // Last bit has already been sampled
                    if (bit_count == DATA_WIDTH) begin

                        rx_data <= rx_shift;

                        busy <= 1'b0;
                        done <= 1'b1;

                        cs   <= 1'b1;
                        mosi <= 1'b0;

                    end

                    else begin

                        // Shift TX data
                        tx_shift <= {
                            tx_shift[DATA_WIDTH-2:0],
                            1'b0
                        };

                        // Present next bit
                        mosi <= tx_shift[DATA_WIDTH-2];

                    end

                end

            end

        end

    end

endmodule