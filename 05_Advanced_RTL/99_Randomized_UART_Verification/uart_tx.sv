`timescale 1ns/1ps

module uart_tx #(
    parameter CLKS_PER_BIT = 4
)(
    input  logic       clk,
    input  logic       rst,

    input  logic [7:0] tx_data,
    input  logic       tx_start,

    output logic       tx,
    output logic       tx_busy,
    output logic       tx_done
);

    localparam IDLE  = 2'd0;
    localparam START = 2'd1;
    localparam DATA  = 2'd2;
    localparam STOP  = 2'd3;

    logic [1:0] state;

    logic [7:0] data_reg;

    integer clk_count;
    integer bit_index;

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            state     <= IDLE;
            data_reg  <= 8'h00;
            clk_count <= 0;
            bit_index <= 0;

            tx        <= 1'b1;
            tx_busy   <= 1'b0;
            tx_done   <= 1'b0;

        end

        else begin

            tx_done <= 1'b0;

            case (state)

                IDLE: begin

                    tx      <= 1'b1;
                    tx_busy <= 1'b0;

                    clk_count <= 0;
                    bit_index <= 0;

                    if (tx_start) begin

                        data_reg <= tx_data;

                        tx_busy <= 1'b1;

                        state <= START;

                    end

                end

                START: begin

                    tx <= 1'b0;

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;
                        bit_index <= 0;

                        state <= DATA;

                    end

                    else begin

                        clk_count <= clk_count + 1;

                    end

                end

                DATA: begin

                    tx <= data_reg[bit_index];

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;

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

                    tx <= 1'b1;

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= 0;

                        tx_busy <= 1'b0;
                        tx_done <= 1'b1;

                        state <= IDLE;

                    end

                    else begin

                        clk_count <= clk_count + 1;

                    end

                end

                default: begin

                    state <= IDLE;

                    tx      <= 1'b1;
                    tx_busy <= 1'b0;

                end

            endcase

        end

    end

endmodule