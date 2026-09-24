`timescale 1ns/1ps

module spi_master #(
    parameter int CLK_DIV = 2
)(
    input  logic       clk,
    input  logic       rst,

    input  logic       start,
    input  logic [7:0] tx_data,

    input  logic       miso,

    output logic       sclk,
    output logic       mosi,
    output logic       cs,

    output logic [7:0] rx_data,
    output logic       busy,
    output logic       done
);

    localparam logic [1:0]
        IDLE = 2'd0,
        RUN  = 2'd1,
        DONE = 2'd2;

    logic [1:0] state;

    logic [15:0] clk_count;

    logic [7:0] tx_shift;
    logic [7:0] rx_shift;

    logic [3:0] bit_count;


    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            state     <= IDLE;

            clk_count <= 16'd0;

            tx_shift  <= 8'd0;
            rx_shift  <= 8'd0;

            bit_count <= 4'd0;

            sclk      <= 1'b0;
            mosi      <= 1'b0;
            cs        <= 1'b1;

            rx_data   <= 8'd0;

            busy      <= 1'b0;
            done      <= 1'b0;

        end

        else begin

            done <= 1'b0;

            case (state)

                //================================================
                // IDLE
                //================================================

                IDLE: begin

                    sclk      <= 1'b0;
                    cs        <= 1'b1;
                    busy      <= 1'b0;

                    clk_count <= 16'd0;
                    bit_count <= 4'd0;

                    if (start) begin

                        state <= RUN;

                        cs   <= 1'b0;
                        busy <= 1'b1;

                        tx_shift <= tx_data;
                        rx_shift <= 8'h00;

                        bit_count <= 4'd0;

                        // First MOSI bit must be valid
                        // before the first rising edge.
                        mosi <= tx_data[7];

                    end

                end


                //================================================
                // SPI CLOCK GENERATION
                // Mode 0:
                //
                // Rising edge  = sample MISO
                // Falling edge = change MOSI
                //================================================

                RUN: begin

                    busy <= 1'b1;
                    cs   <= 1'b0;

                    if (clk_count == CLK_DIV-1) begin

                        clk_count <= 16'd0;

                        if (sclk == 1'b0) begin

                            // Rising edge
                            sclk <= 1'b1;

                            // Sample MISO
                            rx_shift <= {
                                rx_shift[6:0],
                                miso
                            };

                        end

                        else begin

                            // Falling edge
                            sclk <= 1'b0;

                            if (bit_count == 4'd7) begin

                                // All 8 bits have now been sampled.
                                rx_data <= rx_shift;

                                state <= DONE;

                            end

                            else begin

                                bit_count <= bit_count + 1'b1;

                                tx_shift <= {
                                    tx_shift[6:0],
                                    1'b0
                                };

                                // Present next MOSI bit.
                                mosi <= tx_shift[6];

                            end

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                //================================================
                // DONE
                //================================================

                DONE: begin

                    sclk <= 1'b0;
                    cs   <= 1'b1;

                    busy <= 1'b0;
                    done <= 1'b1;

                    mosi <= 1'b0;

                    state <= IDLE;

                end


                default: begin

                    state <= IDLE;

                    sclk <= 1'b0;
                    cs   <= 1'b1;

                    busy <= 1'b0;
                    mosi <= 1'b0;

                end

            endcase

        end

    end

endmodule