`timescale 1ns/1ps

module uart_rx #(
    parameter int CLKS_PER_BIT = 4
)(
    input  logic       clk,
    input  logic       rst,

    input  logic       rx,

    output logic [7:0] data_out,
    output logic       valid,
    output logic       error
);

    typedef enum logic [2:0] {
        IDLE  = 3'd0,
        START = 3'd1,
        DATA  = 3'd2,
        STOP  = 3'd3
    } state_t;

    state_t state;

    logic [$clog2(CLKS_PER_BIT)-1:0] clk_count;

    logic [2:0] bit_index;

    logic [7:0] data_reg;


    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            state     <= IDLE;

            clk_count <= '0;
            bit_index <= '0;
            data_reg  <= '0;

            data_out  <= '0;

            valid     <= 1'b0;
            error     <= 1'b0;

        end

        else begin

            valid <= 1'b0;
            error <= 1'b0;

            case (state)

                //================================================
                // IDLE
                //================================================

                IDLE: begin

                    clk_count <= '0;
                    bit_index <= '0;

                    if (!rx) begin

                        state <= START;

                    end

                end


                //================================================
                // START BIT
                //================================================

                START: begin

                    if (clk_count == (CLKS_PER_BIT/2)-1) begin

                        clk_count <= '0;

                        if (!rx) begin

                            state <= DATA;

                        end

                        else begin

                            state <= IDLE;

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                //================================================
                // DATA
                //================================================

                DATA: begin

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= '0;

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


                //================================================
                // STOP
                //================================================

                STOP: begin

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= '0;

                        if (rx) begin

                            data_out <= data_reg;

                            valid <= 1'b1;

                        end

                        else begin

                            error <= 1'b1;

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