`timescale 1ns/1ps

module protocol_master #(
    parameter int TIMEOUT = 8
)(
    input  logic       clk,
    input  logic       rst,

    input  logic       start,
    input  logic [7:0] tx_data,

    input  logic       ack,
    input  logic [7:0] rx_data,

    output logic       req,
    output logic [7:0] data_out,

    output logic       busy,
    output logic       done,
    output logic       timeout
);

    typedef enum logic [1:0] {
        IDLE    = 2'd0,
        WAIT_ACK = 2'd1,
        DONE    = 2'd2,
        TIMEOUT_STATE = 2'd3
    } state_t;

    state_t state;

    logic [3:0] timer;


    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            state    <= IDLE;

            timer    <= 0;

            req      <= 0;
            data_out <= 0;

            busy     <= 0;
            done     <= 0;
            timeout  <= 0;

        end

        else begin

            done    <= 0;
            timeout <= 0;

            case (state)

                //================================================
                // IDLE
                //================================================

                IDLE: begin

                    req   <= 0;
                    busy  <= 0;
                    timer <= 0;

                    if (start) begin

                        req      <= 1;
                        data_out <= tx_data;

                        busy  <= 1;

                        timer <= 0;

                        state <= WAIT_ACK;

                    end

                end


                //================================================
                // WAIT FOR ACK
                //================================================

                WAIT_ACK: begin

                    req  <= 1;
                    busy <= 1;

                    if (ack) begin

                        req <= 0;

                        busy <= 0;

                        done <= 1;

                        state <= DONE;

                    end

                    else if (timer == TIMEOUT-1) begin

                        req <= 0;

                        busy <= 0;

                        timeout <= 1;

                        state <= TIMEOUT_STATE;

                    end

                    else begin

                        timer <= timer + 1'b1;

                    end

                end


                //================================================
                // DONE
                //================================================

                DONE: begin

                    req   <= 0;
                    busy  <= 0;

                    state <= IDLE;

                end


                //================================================
                // TIMEOUT
                //================================================

                TIMEOUT_STATE: begin

                    req   <= 0;
                    busy  <= 0;

                    state <= IDLE;

                end


                default: begin

                    state <= IDLE;

                    req  <= 0;
                    busy <= 0;

                end

            endcase

        end

    end

endmodule