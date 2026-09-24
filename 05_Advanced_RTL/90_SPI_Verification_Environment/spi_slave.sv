`timescale 1ns/1ps

module spi_slave (
    input  logic       clk,
    input  logic       rst,

    input  logic       cs,
    input  logic       sclk,
    input  logic       mosi,

    output logic       miso,

    input  logic [7:0] tx_data,

    output logic [7:0] rx_data,
    output logic       done
);

    logic [7:0] tx_shift;
    logic [7:0] rx_shift;

    logic [3:0] bit_count;


    //============================================================
    // Reset / chip-select handling
    //============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            tx_shift  <= 8'h00;
            rx_shift  <= 8'h00;

            bit_count <= 4'd0;

            miso      <= 1'b0;
            rx_data   <= 8'h00;
            done      <= 1'b0;

        end

        else begin

            done <= 1'b0;

            if (cs) begin

                // Slave inactive

                tx_shift  <= tx_data;
                rx_shift  <= 8'h00;

                bit_count <= 4'd0;

                miso <= 1'b0;

            end

            else begin

                // While CS is active, the SPI clock edge
                // processing is handled below.
                //
                // The initial MSB is already placed on MISO
                // when CS becomes active.

            end

        end

    end


    //============================================================
    // SPI MODE 0 - RISING EDGE
    //
    // Sample MOSI.
    //============================================================

    always @(posedge sclk) begin

        if (!cs) begin

            rx_shift <= {
                rx_shift[6:0],
                mosi
            };

        end

    end


    //============================================================
    // SPI MODE 0 - FALLING EDGE
    //
    // Change MISO for the next bit.
    //============================================================

    always @(negedge sclk) begin

        if (!cs) begin

            if (bit_count == 4'd7) begin

                rx_data <= rx_shift;

                done <= 1'b1;

                miso <= 1'b0;

                bit_count <= 4'd0;

            end

            else begin

                bit_count <= bit_count + 1'b1;

                tx_shift <= {
                    tx_shift[6:0],
                    1'b0
                };

                miso <= tx_shift[6];

            end

        end

    end


    //============================================================
    // Detect CS activation and put first MISO bit on bus.
    //============================================================

    always @(negedge cs) begin

        tx_shift  <= tx_data;

        rx_shift  <= 8'h00;

        bit_count <= 4'd0;

        // First bit must already be available before
        // the first rising SCLK edge.
        miso <= tx_data[7];

    end

endmodule