`timescale 1ns/1ps

module uart_tx #(
    parameter int CLKS_PER_BIT = 4
)(
    input  logic       clk,
    input  logic       rst,

    input  logic       start,
    input  logic [7:0] data_in,

    output logic       tx,
    output logic       busy,
    output logic       done
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

            tx        <= 1'b1;
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

                    tx        <= 1'b1;
                    busy      <= 1'b0;
                    clk_count <= '0;
                    bit_index <= '0;

                    if (start) begin

                        data_reg <= data_in;

                        busy <= 1'b1;

                        state <= START;

                    end

                end


                //================================================
                // START BIT
                //================================================

                START: begin

                    tx <= 1'b0;

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= '0;

                        bit_index <= 3'd0;

                        state <= DATA;

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                //================================================
                // DATA BITS
                //================================================

                DATA: begin

                    tx <= data_reg[bit_index];

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= '0;

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
                // STOP BIT
                //================================================

                STOP: begin

                    tx <= 1'b1;

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= '0;

                        busy <= 1'b0;
                        done <= 1'b1;

                        state <= IDLE;

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                default: begin

                    state <= IDLE;

                    tx   <= 1'b1;
                    busy <= 1'b0;

                end

            endcase

        end

    end

endmodule