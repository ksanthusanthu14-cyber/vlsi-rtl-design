`timescale 1ns/1ps

module spi_slave #(
    parameter DATA_WIDTH = 8
)(
    input  logic                  rst,

    input  logic                  cs,
    input  logic                  sclk,
    input  logic                  mosi,

    input  logic [DATA_WIDTH-1:0] tx_data,

    output logic [DATA_WIDTH-1:0] rx_data,
    output logic                  rx_valid,

    output logic                  miso
);

    logic [DATA_WIDTH-1:0] tx_shift;
    logic [DATA_WIDTH-1:0] rx_shift;

    integer bit_count;

    // =========================================================
    // SPI SLAVE - MODE 0
    //
    // Rising edge  : sample MOSI
    // Falling edge : update MISO
    // =========================================================

    always @(posedge sclk or
             negedge sclk or
             posedge cs or
             negedge cs or
             posedge rst) begin

        if (rst) begin

            tx_shift <= 0;
            rx_shift <= 0;
            rx_data  <= 0;

            rx_valid <= 1'b0;

            miso <= 1'b0;

            bit_count <= 0;

        end

        // -----------------------------------------------------
        // CS ASSERTION
        // -----------------------------------------------------

        else if (!cs && !sclk && bit_count == 0) begin

            tx_shift <= tx_data;

            miso <= tx_data[DATA_WIDTH-1];

            rx_valid <= 1'b0;

        end

        // -----------------------------------------------------
        // CS DEASSERTION
        // -----------------------------------------------------

        else if (cs) begin

            rx_data <= rx_shift;

            rx_valid <= 1'b1;

            bit_count <= 0;

            miso <= 1'b0;

        end

        // -----------------------------------------------------
        // RISING EDGE
        // -----------------------------------------------------

        else if (!cs && sclk) begin

            rx_shift <= {
                rx_shift[DATA_WIDTH-2:0],
                mosi
            };

            bit_count <= bit_count + 1;

        end

        // -----------------------------------------------------
        // FALLING EDGE
        // -----------------------------------------------------

        else if (!cs && !sclk) begin

            if (bit_count > 0 &&
                bit_count < DATA_WIDTH) begin

                tx_shift <= {
                    tx_shift[DATA_WIDTH-2:0],
                    1'b0
                };

                miso <= tx_shift[DATA_WIDTH-2];

            end

        end

    end

endmodule