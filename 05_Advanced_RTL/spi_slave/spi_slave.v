`timescale 1ns/1ps

module spi_slave #(
    parameter DATA_WIDTH = 8
)(
    input  wire                  rst,

    // SPI interface
    input  wire                  sclk,
    input  wire                  cs_n,
    input  wire                  mosi,
    output reg                   miso,

    // Parallel interface
    input  wire [DATA_WIDTH-1:0] tx_data,
    output reg  [DATA_WIDTH-1:0] rx_data,

    output reg                   done
);

    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [DATA_WIDTH-1:0] rx_shift_reg;

    reg [3:0] bit_count;


    // =========================================================
    // CHIP SELECT
    // =========================================================

    always @(negedge cs_n or posedge rst) begin

        if (rst) begin

            tx_shift_reg <= {DATA_WIDTH{1'b0}};
            rx_shift_reg <= {DATA_WIDTH{1'b0}};

            rx_data <= {DATA_WIDTH{1'b0}};

            bit_count <= 4'd0;

            miso <= 1'b0;
            done <= 1'b0;

        end

        else begin

            // Load slave transmit data
            tx_shift_reg <= tx_data;

            // Clear receive shift register
            rx_shift_reg <= {DATA_WIDTH{1'b0}};

            bit_count <= 4'd0;

            done <= 1'b0;

            // First MSB available immediately
            miso <= tx_data[DATA_WIDTH-1];

        end

    end


    // =========================================================
    // SPI MODE 0
    //
    // Rising edge:
    //     Receive MOSI
    //
    // Falling edge:
    //     Change MISO
    // =========================================================


    // =========================================================
    // RECEIVE MOSI
    // =========================================================

    always @(posedge sclk) begin

        if (!cs_n) begin

            // Shift in MOSI
            rx_shift_reg <= {
                rx_shift_reg[DATA_WIDTH-2:0],
                mosi
            };


            // Last bit
            if (bit_count == DATA_WIDTH-1) begin

                // Include current MOSI bit directly
                rx_data <= {
                    rx_shift_reg[DATA_WIDTH-2:0],
                    mosi
                };

                done <= 1'b1;

            end

        end

    end


    // =========================================================
    // TRANSMIT MISO
    // =========================================================

    always @(negedge sclk) begin

        if (!cs_n) begin

            if (bit_count < DATA_WIDTH-1) begin

                bit_count <= bit_count + 1'b1;

                tx_shift_reg <= {
                    tx_shift_reg[DATA_WIDTH-2:0],
                    1'b0
                };

                miso <= tx_shift_reg[DATA_WIDTH-2];

            end

            else begin

                miso <= 1'b0;

            end

        end

    end


    // =========================================================
    // CHIP SELECT DEASSERTED
    // =========================================================

    always @(posedge cs_n) begin

        miso <= 1'b0;

        done <= 1'b0;

        bit_count <= 4'd0;

    end

endmodule