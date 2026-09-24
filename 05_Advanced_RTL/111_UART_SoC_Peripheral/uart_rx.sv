`timescale 1ns/1ps

module uart_rx #(
    parameter integer CLK_PER_BIT = 4
)(
    input  logic       clk,
    input  logic       rst,

    input  logic       rx,

    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       rx_error
);

    typedef enum logic [1:0] {
        RX_IDLE,
        RX_START,
        RX_DATA,
        RX_STOP
    } state_t;

    state_t state;

    logic [7:0] data_reg;
    logic [2:0] bit_index;
    integer baud_count;

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            state      <= RX_IDLE;
            data_reg   <= 8'h00;
            rx_data    <= 8'h00;
            rx_valid   <= 1'b0;
            rx_error   <= 1'b0;
            bit_index  <= 3'd0;
            baud_count <= 0;
        end

        else begin

            rx_valid <= 1'b0;
            rx_error <= 1'b0;

            case (state)

                RX_IDLE: begin
                    if (rx == 1'b0) begin
                        baud_count <= 0;
                        state      <= RX_START;
                    end
                end

                RX_START: begin
                    if (baud_count == (CLK_PER_BIT/2)-1) begin

                        baud_count <= 0;

                        if (rx == 1'b0) begin
                            bit_index <= 3'd0;
                            state     <= RX_DATA;
                        end
                        else begin
                            state <= RX_IDLE;
                        end

                    end
                    else begin
                        baud_count <= baud_count + 1;
                    end
                end

                RX_DATA: begin

                    if (baud_count == CLK_PER_BIT-1) begin

                        baud_count <= 0;

                        data_reg[bit_index] <= rx;

                        if (bit_index == 3'd7) begin
                            state <= RX_STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end

                    end
                    else begin
                        baud_count <= baud_count + 1;
                    end

                end

                RX_STOP: begin

                    if (baud_count == CLK_PER_BIT-1) begin

                        baud_count <= 0;

                        if (rx == 1'b1) begin
                            rx_data  <= data_reg;
                            rx_valid <= 1'b1;
                        end
                        else begin
                            rx_error <= 1'b1;
                        end

                        state <= RX_IDLE;

                    end
                    else begin
                        baud_count <= baud_count + 1;
                    end

                end

                default: begin
                    state <= RX_IDLE;
                end

            endcase
        end
    end

endmodule