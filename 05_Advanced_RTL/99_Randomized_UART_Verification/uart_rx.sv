`timescale 1ns/1ps

module uart_rx #(
    parameter CLKS_PER_BIT = 4
)(
    input  logic       clk,
    input  logic       rst,

    input  logic       rx,

    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       rx_error
);

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    logic [2:0] state;

    logic [7:0] data_reg;

    integer clk_count;
    integer bit_index;

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            state     <= IDLE;

            data_reg  <= 8'h00;
            rx_data   <= 8'h00;

            rx_valid  <= 1'b0;
            rx_error  <= 1'b0;

            clk_count <= 0;
            bit_index <= 0;

        end

        else begin

            rx_valid <= 1'b0;
            rx_error <= 1'b0;

            case (state)

                IDLE: begin

                    clk_count <= 0;
                    bit_index <= 0;

                    if (rx == 1'b0)
                        state <= START;

                end

                START: begin

                    if (clk_count == (CLKS_PER_BIT/2)-1) begin

                        clk_count <= 0;

                        if (rx == 1'b0) begin

                            bit_index <= 0;

                            state <= DATA;

                        end

                        else begin

                            state <= IDLE;

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1;

                    end

                end

                DATA: begin

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;

                        data_reg[bit_index] <= rx;

                        if (bit_index == 7) begin

                            state <= STOP;

                        end

                        else begin

                            bit_index <= bit_index + 1;

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1;

                    end

                end

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

                        clk_count <= clk_count + 1;

                    end

                end

                default: begin

                    state <= IDLE;

                end

            endcase

        end

    end

endmodule