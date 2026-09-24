`timescale 1ns/1ps

module uart_rx #(
    parameter int DATA_WIDTH   = 8,
    parameter int CLKS_PER_BIT = 4
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  rx,

    output logic [DATA_WIDTH-1:0] rx_data,
    output logic                  rx_valid,
    output logic                  rx_busy,
    output logic                  rx_error
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

            rx_data   <= '0;
            rx_valid  <= 1'b0;
            rx_busy   <= 1'b0;
            rx_error  <= 1'b0;

        end

        else begin

            rx_valid <= 1'b0;
            rx_error <= 1'b0;

            case (state)

                //========================================
                // IDLE
                //========================================

                IDLE: begin

                    rx_busy   <= 1'b0;
                    clk_count <= '0;
                    bit_index <= '0;

                    if (rx == 1'b0) begin

                        rx_busy   <= 1'b1;
                        clk_count <= '0;
                        state     <= START_BIT;

                    end

                end


                //========================================
                // VERIFY START BIT
                //========================================

                START_BIT: begin

                    rx_busy <= 1'b1;

                    // Sample middle of start bit
                    if (clk_count == (CLKS_PER_BIT/2)-1) begin

                        if (rx == 1'b0) begin

                            clk_count <= '0;
                            bit_index <= '0;
                            state     <= DATA_BITS;

                        end

                        else begin

                            state <= IDLE;
                            rx_busy <= 1'b0;

                        end

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                //========================================
                // RECEIVE DATA
                //========================================

                DATA_BITS: begin

                    rx_busy <= 1'b1;

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= '0;

                        data_reg[bit_index] <= rx;

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

                    rx_busy <= 1'b1;

                    if (clk_count == CLKS_PER_BIT-1) begin

                        clk_count <= '0;

                        if (rx == 1'b1) begin

                            rx_data  <= data_reg;
                            rx_valid <= 1'b1;
                            rx_error <= 1'b0;

                        end

                        else begin

                            rx_error <= 1'b1;

                        end

                        rx_busy <= 1'b0;
                        state   <= IDLE;

                    end

                    else begin

                        clk_count <= clk_count + 1'b1;

                    end

                end


                default: begin

                    state <= IDLE;
                    rx_busy <= 1'b0;

                end

            endcase

        end

    end

endmodule