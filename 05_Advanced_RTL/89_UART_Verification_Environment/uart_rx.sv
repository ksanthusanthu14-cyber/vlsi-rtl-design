`timescale 1ns/1ps

module uart_rx #(
    parameter int CLKS_PER_BIT = 4
)(
    input  logic       clk,
    input  logic       rst,

    input  logic       rx,

    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       rx_error
);

    localparam logic [2:0]
        IDLE  = 3'd0,
        START = 3'd1,
        DATA  = 3'd2,
        STOP  = 3'd3;

    logic [2:0] state;

    logic [15:0] clk_count;
    logic [2:0]  bit_index;

    logic [7:0] data_reg;


    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            state     <= IDLE;

            clk_count <= 0;
            bit_index <= 0;

            data_reg  <= 0;
            rx_data   <= 0;

            rx_valid  <= 1'b0;
            rx_error  <= 1'b0;

        end

        else begin

            rx_valid <= 1'b0;
            rx_error <= 1'b0;

            case (state)

                //======================================
                // IDLE
                //======================================

                IDLE: begin

                    clk_count <= 0;
                    bit_index <= 0;

                    if (rx == 1'b0) begin

                        state <= START;

                    end

                end


                //======================================
                // START BIT
                //======================================

                START: begin

                    if (clk_count ==
                        (CLKS_PER_BIT/2)-1) begin

                        clk_count <= 0;

                        if (rx == 1'b0) begin

                            state <= DATA;

                        end

                        else begin

                            rx_error <= 1'b1;

                            state <= IDLE;

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                //======================================
                // DATA BITS
                //======================================

                DATA: begin

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;

                        data_reg[bit_index] <= rx;

                        if (bit_index == 3'd7) begin

                            state <= STOP;

                        end

                        else begin

                            bit_index <= bit_index + 1'b1;

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                //======================================
                // STOP BIT
                //======================================

                STOP: begin

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;

                        if (rx == 1'b1) begin

                            rx_data  <= data_reg;

                            rx_valid <= 1'b1;

                        end

                        else begin

                            rx_error <= 1'b1;

                        end

                        state <= IDLE;

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                default: begin

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule