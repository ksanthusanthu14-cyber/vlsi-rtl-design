`timescale 1ns/1ps

module uart_tx #(
    parameter integer CLK_PER_BIT = 4
)(
    input  logic       clk,
    input  logic       rst,

    input  logic       tx_start,
    input  logic [7:0] tx_data,

    output logic       tx,
    output logic       busy,
    output logic       done
);

    typedef enum logic [1:0] {
        IDLE,
        START,
        DATA,
        STOP
    } state_t;

    state_t state;

    logic [7:0] data_reg;
    logic [2:0] bit_index;
    integer baud_count;

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            state      <= IDLE;
            data_reg   <= 8'h00;
            bit_index  <= 3'd0;
            baud_count <= 0;

            tx         <= 1'b1;
            busy       <= 1'b0;
            done       <= 1'b0;
        end

        else begin

            done <= 1'b0;

            case (state)

                IDLE: begin
                    tx   <= 1'b1;
                    busy <= 1'b0;

                    if (tx_start) begin
                        data_reg   <= tx_data;
                        bit_index  <= 3'd0;
                        baud_count <= 0;
                        busy       <= 1'b1;
                        state      <= START;
                        tx         <= 1'b0;
                    end
                end

                START: begin
                    if (baud_count == CLK_PER_BIT-1) begin
                        baud_count <= 0;
                        state      <= DATA;
                        tx         <= data_reg[0];
                    end
                    else begin
                        baud_count <= baud_count + 1;
                    end
                end

                DATA: begin
                    if (baud_count == CLK_PER_BIT-1) begin

                        baud_count <= 0;

                        if (bit_index == 3'd7) begin
                            state <= STOP;
                            tx    <= 1'b1;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                            tx        <= data_reg[bit_index + 1'b1];
                        end

                    end
                    else begin
                        baud_count <= baud_count + 1;
                    end
                end

                STOP: begin
                    if (baud_count == CLK_PER_BIT-1) begin
                        baud_count <= 0;
                        state      <= IDLE;
                        tx         <= 1'b1;
                        busy       <= 1'b0;
                        done       <= 1'b1;
                    end
                    else begin
                        baud_count <= baud_count + 1;
                    end
                end

                default: begin
                    state <= IDLE;
                    tx    <= 1'b1;
                    busy  <= 1'b0;
                end

            endcase
        end
    end

endmodule