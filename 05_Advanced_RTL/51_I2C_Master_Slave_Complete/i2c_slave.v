`timescale 1ns/1ps

module i2c_slave #(
    parameter SLAVE_ADDR = 7'h50
)(
    input wire clk,
    input wire rst,

    input wire scl,
    input wire sda_in,

    output reg sda_out,
    output reg sda_oe,

    input wire [7:0] tx_data,

    output reg [7:0] rx_data,
    output reg data_valid,
    output reg read_request
);

    // =========================================================
    // STATES
    // =========================================================

    localparam STATE_IDLE        = 4'd0;
    localparam STATE_ADDRESS     = 4'd1;

    localparam STATE_ADDR_ACK_L  = 4'd2;
    localparam STATE_ADDR_ACK_H  = 4'd3;

    localparam STATE_RECEIVE     = 4'd4;

    localparam STATE_RX_ACK_L    = 4'd5;
    localparam STATE_RX_ACK_H    = 4'd6;

    localparam STATE_TRANSMIT    = 4'd7;

    localparam STATE_TX_ACK      = 4'd8;


    reg [3:0] state;

    reg scl_d;
    reg sda_d;

    reg [7:0] shift_reg;

    reg [7:0] tx_shift;

    reg [2:0] bit_count;

    reg [6:0] address_reg;

    reg rw_reg;

    reg address_match;


    // =========================================================
    // EDGE DETECTION
    // =========================================================

    wire scl_rise = scl && !scl_d;

    wire scl_fall = !scl && scl_d;

    wire start_condition =
        scl &&
        sda_d &&
        !sda_in;

    wire stop_condition =
        scl &&
        !sda_d &&
        sda_in;


    // =========================================================
    // SLAVE LOGIC
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state         <= STATE_IDLE;

            scl_d         <= 1'b1;

            sda_d         <= 1'b1;

            shift_reg     <= 8'd0;

            tx_shift      <= 8'd0;

            bit_count     <= 3'd0;

            address_reg   <= 7'd0;

            rw_reg        <= 1'b0;

            address_match <= 1'b0;

            rx_data       <= 8'd0;

            data_valid    <= 1'b0;

            read_request  <= 1'b0;

            sda_oe        <= 1'b0;

            sda_out       <= 1'b1;

        end

        else begin

            // Save previous bus values

            scl_d <= scl;

            sda_d <= sda_in;

            // Pulsed outputs

            data_valid   <= 1'b0;

            read_request <= 1'b0;


            // =================================================
            // START CONDITION
            // =================================================

            if (start_condition) begin

                state <= STATE_ADDRESS;

                bit_count <= 3'd0;

                shift_reg <= 8'd0;

                sda_oe <= 1'b0;

            end


            // =================================================
            // STOP CONDITION
            // =================================================

            else if (stop_condition) begin

                state <= STATE_IDLE;

                bit_count <= 3'd0;

                sda_oe <= 1'b0;

            end


            // =================================================
            // SCL RISING EDGE
            // =================================================

            else if (scl_rise) begin

                case (state)

                    // =========================================
                    // ADDRESS
                    // =========================================

                    STATE_ADDRESS: begin

                        shift_reg <= {
                            shift_reg[6:0],
                            sda_in
                        };


                        if (bit_count == 3'd7) begin

                            address_reg <= shift_reg[6:0];

                            rw_reg <= sda_in;

                            if (shift_reg[6:0] == SLAVE_ADDR) begin

                                address_match <= 1'b1;

                                state <= STATE_ADDR_ACK_L;

                            end

                            else begin

                                address_match <= 1'b0;

                                state <= STATE_IDLE;

                            end

                            bit_count <= 3'd0;

                        end

                        else begin

                            bit_count <= bit_count + 1'b1;

                        end

                    end


                    // =========================================
                    // ADDRESS ACK HIGH
                    // =========================================

                    STATE_ADDR_ACK_H: begin

                        sda_oe <= 1'b0;


                        if (rw_reg) begin

                            // Slave transmitter

                            tx_shift <= tx_data;

                            bit_count <= 3'd7;

                            read_request <= 1'b1;

                            state <= STATE_TRANSMIT;

                        end

                        else begin

                            // Slave receiver

                            bit_count <= 3'd0;

                            state <= STATE_RECEIVE;

                        end

                    end


                    // =========================================
                    // RECEIVE DATA
                    // =========================================

                    STATE_RECEIVE: begin

                        shift_reg <= {
                            shift_reg[6:0],
                            sda_in
                        };


                        if (bit_count == 3'd7) begin

                            rx_data <= {
                                shift_reg[6:0],
                                sda_in
                            };

                            data_valid <= 1'b1;

                            bit_count <= 3'd0;

                            state <= STATE_RX_ACK_L;

                        end

                        else begin

                            bit_count <= bit_count + 1'b1;

                        end

                    end


                    // =========================================
                    // RX ACK HIGH
                    // =========================================

                    STATE_RX_ACK_H: begin

                        sda_oe <= 1'b0;

                        state <= STATE_IDLE;

                    end


                    // =========================================
                    // TRANSMIT
                    // =========================================

                    STATE_TRANSMIT: begin

                        if (bit_count == 0) begin

                            state <= STATE_TX_ACK;

                        end

                        else begin

                            bit_count <= bit_count - 1'b1;

                        end

                    end


                    // =========================================
                    // TRANSMIT ACK
                    // =========================================

                    STATE_TX_ACK: begin

                        // Master ACK/NACK is sampled here

                        sda_oe <= 1'b0;

                        state <= STATE_IDLE;

                    end


                    default: begin

                    end

                endcase

            end


            // =================================================
            // SCL FALLING EDGE
            // =================================================

            else if (scl_fall) begin

                case (state)

                    // =========================================
                    // ADDRESS ACK LOW
                    // =========================================

                    STATE_ADDR_ACK_L: begin

                        if (address_match)

                            sda_oe <= 1'b1;

                        else

                            sda_oe <= 1'b0;

                        state <= STATE_ADDR_ACK_H;

                    end


                    // =========================================
                    // RECEIVE ACK LOW
                    // =========================================

                    STATE_RX_ACK_L: begin

                        // ACK = SDA LOW

                        sda_oe <= 1'b1;

                        state <= STATE_RX_ACK_H;

                    end


                    // =========================================
                    // TRANSMIT DATA
                    // =========================================

                    STATE_TRANSMIT: begin

                        if (bit_count == 3'd7) begin

                            sda_oe <= ~tx_shift[7];

                        end

                        else if (bit_count == 3'd6) begin

                            sda_oe <= ~tx_shift[6];

                        end

                        else if (bit_count == 3'd5) begin

                            sda_oe <= ~tx_shift[5];

                        end

                        else if (bit_count == 3'd4) begin

                            sda_oe <= ~tx_shift[4];

                        end

                        else if (bit_count == 3'd3) begin

                            sda_oe <= ~tx_shift[3];

                        end

                        else if (bit_count == 3'd2) begin

                            sda_oe <= ~tx_shift[2];

                        end

                        else if (bit_count == 3'd1) begin

                            sda_oe <= ~tx_shift[1];

                        end

                        else begin

                            sda_oe <= ~tx_shift[0];

                        end

                    end


                    // =========================================
                    // TRANSMIT ACK
                    // =========================================

                    STATE_TX_ACK: begin

                        // Release SDA for master ACK/NACK

                        sda_oe <= 1'b0;

                    end


                    default: begin

                    end

                endcase

            end

        end

    end


    // =========================================================
    // SDA OUTPUT
    // =========================================================

    always @(*) begin

        if (sda_oe)

            sda_out = 1'b0;

        else

            sda_out = 1'b1;

    end

endmodule