`timescale 1ns/1ps

module uart_tx #(
    parameter int DATA_WIDTH    = 8,
    parameter int CLKS_PER_BIT  = 4
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  tx_start,
    input  logic [DATA_WIDTH-1:0] tx_data,

    output logic                  tx,
    output logic                  tx_busy,
    output logic                  tx_done
);

    localparam int CLK_COUNT_WIDTH =
        (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);

    localparam int BIT_COUNT_WIDTH =
        (DATA_WIDTH <= 1) ? 1 : $clog2(DATA_WIDTH);

    typedef enum logic [1:0] {
        IDLE,
        START_BIT,
        DATA_BITS,
        STOP_BIT
    } state_t;

    state_t state;

    logic [CLK_COUNT_WIDTH-1:0] clk_count;
    logic [BIT_COUNT_WIDTH-1:0] bit_index;
    logic [DATA_WIDTH-1:0] data_reg;


    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            state     <= IDLE;
            clk_count <= '0;
            bit_index <= '0;
            data_reg  <= '0;

            tx        <= 1'b1;
            tx_busy   <= 1'b0;
            tx_done   <= 1'b0;

        end

        else begin

            tx_done <= 1'b0;

            case (state)

                //========================================
                // IDLE
                //========================================

                IDLE: begin

                    tx      <= 1'b1;
                    tx_busy <= 1'b0;
                    clk_count <= '0;
                    bit_index <= '0;

                    if (tx_start) begin

                        data_reg <= tx_data;

                        tx_busy <= 1'b1;
                        state   <= START_BIT;

                    end

                end


                //========================================
                // START BIT
                //========================================

                START_BIT: begin

                    tx      <= 1'b0;
                    tx_busy <= 1'b1;

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= '0;
                        bit_index <= '0;
                        state     <= DATA_BITS;

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                //========================================
                // DATA BITS
                //========================================

                DATA_BITS: begin

                    tx      <= data_reg[bit_index];
                    tx_busy <= 1'b1;

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= '0;

                        if (bit_index == DATA_WIDTH-1) begin

                            bit_index <= '0;
                            state     <= STOP_BIT;

                        end

                        else begin

                            bit_index <= bit_index + 1'b1;

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                //========================================
                // STOP BIT
                //========================================

                STOP_BIT: begin

                    tx      <= 1'b1;
                    tx_busy <= 1'b1;

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= '0;
                        tx_busy   <= 1'b0;
                        tx_done   <= 1'b1;
                        state     <= IDLE;

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                default: begin

                    state <= IDLE;
                    tx    <= 1'b1;

                end

            endcase

        end

    end

endmodule