`timescale 1ns/1ps

module spi_master #(
    parameter DATA_WIDTH = 8,
    parameter CLK_DIV = 2
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire                  start,
    input  wire [DATA_WIDTH-1:0] tx_data,
    input  wire                  miso,

    output reg                   mosi,
    output reg                   sclk,
    output reg                   cs_n,
    output reg [DATA_WIDTH-1:0]  rx_data,
    output reg                   busy,
    output reg                   done
);

    reg [DATA_WIDTH-1:0] tx_shift_reg;
    reg [DATA_WIDTH-1:0] rx_shift_reg;

    reg [31:0] clk_counter;
    reg [31:0] bit_count;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            mosi         <= 1'b0;
            sclk         <= 1'b0;
            cs_n         <= 1'b1;

            rx_data      <= {DATA_WIDTH{1'b0}};

            busy         <= 1'b0;
            done         <= 1'b0;

            tx_shift_reg <= {DATA_WIDTH{1'b0}};
            rx_shift_reg <= {DATA_WIDTH{1'b0}};

            clk_counter  <= 32'd0;
            bit_count    <= 32'd0;

        end

        else begin

            // DONE is a one-clock pulse
            done <= 1'b0;

            // =================================================
            // IDLE
            // =================================================

            if (!busy) begin

                sclk        <= 1'b0;
                cs_n        <= 1'b1;
                clk_counter <= 32'd0;
                bit_count   <= 32'd0;

                if (start) begin

                    busy         <= 1'b1;
                    cs_n         <= 1'b0;

                    tx_shift_reg <= tx_data;
                    rx_shift_reg <= {DATA_WIDTH{1'b0}};

                    // Send MSB first
                    mosi <= tx_data[DATA_WIDTH-1];

                end

            end

            // =================================================
            // SPI TRANSFER
            // =================================================

            else begin

                if (clk_counter == CLK_DIV-1) begin

                    clk_counter <= 32'd0;

                    // -----------------------------------------
                    // Rising edge
                    // Sample MISO
                    // -----------------------------------------

                    if (sclk == 1'b0) begin

                        sclk <= 1'b1;

                        rx_shift_reg <= {
                            rx_shift_reg[DATA_WIDTH-2:0],
                            miso
                        };

                        // Last bit
                        if (bit_count == DATA_WIDTH-1) begin

                            rx_data <= {
                                rx_shift_reg[DATA_WIDTH-2:0],
                                miso
                            };

                        end

                    end

                    // -----------------------------------------
                    // Falling edge
                    // Change MOSI
                    // -----------------------------------------

                    else begin

                        sclk <= 1'b0;

                        if (bit_count == DATA_WIDTH-1) begin

                            busy <= 1'b0;
                            cs_n <= 1'b1;
                            done <= 1'b1;
                            mosi <= 1'b0;

                        end

                        else begin

                            bit_count <= bit_count + 1'b1;

                            tx_shift_reg <= {
                                tx_shift_reg[DATA_WIDTH-2:0],
                                1'b0
                            };

                            mosi <= tx_shift_reg[DATA_WIDTH-2];

                        end

                    end

                end

                else begin

                    clk_counter <= clk_counter + 1'b1;

                end

            end

        end

    end

endmodule