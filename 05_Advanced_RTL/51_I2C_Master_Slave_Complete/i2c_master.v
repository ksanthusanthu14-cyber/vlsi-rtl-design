`timescale 1ns/1ps

module i2c_master #(
    parameter CLK_DIV = 2
)(
    input wire clk,
    input wire rst,

    input wire start,
    input wire rw,

    input wire [6:0] slave_addr,
    input wire [7:0] tx_data,

    input wire sda_in,

    output reg scl,
    output reg sda_out,
    output reg sda_oe,

    output reg [7:0] rx_data,

    output reg busy,
    output reg done,
    output reg ack_error
);

    // =========================================================
    // STATES
    // =========================================================

    localparam STATE_IDLE          = 4'd0;
    localparam STATE_START         = 4'd1;

    localparam STATE_ADDR_HIGH     = 4'd2;
    localparam STATE_ADDR_LOW      = 4'd3;

    localparam STATE_ADDR_ACK_HIGH = 4'd4;
    localparam STATE_ADDR_ACK_LOW  = 4'd5;

    localparam STATE_DATA_HIGH     = 4'd6;
    localparam STATE_DATA_LOW      = 4'd7;

    localparam STATE_DATA_ACK_HIGH = 4'd8;
    localparam STATE_DATA_ACK_LOW  = 4'd9;

    localparam STATE_READ_HIGH     = 4'd10;
    localparam STATE_READ_LOW      = 4'd11;

    localparam STATE_READ_ACK_HIGH = 4'd12;
    localparam STATE_READ_ACK_LOW  = 4'd13;

    localparam STATE_STOP_1        = 4'd14;
    localparam STATE_STOP_2        = 4'd15;


    reg [3:0] state;

    reg [15:0] clk_count;

    reg [7:0] address_shift;

    reg [7:0] tx_shift;

    reg [7:0] rx_shift;

    reg [2:0] bit_count;


    // =========================================================
    // CLOCK DIVIDER TICK
    // =========================================================

    wire tick = (clk_count == CLK_DIV-1);


    // =========================================================
    // MAIN FSM
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state         <= STATE_IDLE;

            clk_count     <= 16'd0;

            scl           <= 1'b1;

            sda_out       <= 1'b1;

            sda_oe        <= 1'b0;

            rx_data       <= 8'd0;

            busy          <= 1'b0;

            done          <= 1'b0;

            ack_error     <= 1'b0;

            address_shift <= 8'd0;

            tx_shift      <= 8'd0;

            rx_shift      <= 8'd0;

            bit_count     <= 3'd0;

        end

        else begin

            done <= 1'b0;


            if (!tick) begin

                clk_count <= clk_count + 1'b1;

            end

            else begin

                clk_count <= 16'd0;


                case (state)

                    // =================================================
                    // IDLE
                    // =================================================

                    STATE_IDLE: begin

                        scl     <= 1'b1;
                        sda_oe  <= 1'b0;
                        sda_out <= 1'b1;

                        busy <= 1'b0;

                        if (start) begin

                            busy      <= 1'b1;

                            ack_error <= 1'b0;

                            address_shift <= {
                                slave_addr,
                                rw
                            };

                            tx_shift <= tx_data;

                            bit_count <= 3'd7;

                            // START:
                            // SDA goes LOW while SCL is HIGH

                            sda_oe <= 1'b1;

                            state <= STATE_START;

                        end

                    end


                    // =================================================
                    // START
                    // =================================================

                    STATE_START: begin

                        // Pull SCL LOW after START

                        scl <= 1'b0;

                        sda_oe <= ~address_shift[7];

                        state <= STATE_ADDR_HIGH;

                    end


                    // =================================================
                    // ADDRESS HIGH
                    // =================================================

                    STATE_ADDR_HIGH: begin

                        scl <= 1'b1;

                        state <= STATE_ADDR_LOW;

                    end


                    // =================================================
                    // ADDRESS LOW
                    // =================================================

                    STATE_ADDR_LOW: begin

                        scl <= 1'b0;

                        if (bit_count == 0) begin

                            // Release SDA for ACK

                            sda_oe <= 1'b0;

                            state <= STATE_ADDR_ACK_HIGH;

                        end

                        else begin

                            bit_count <= bit_count - 1'b1;

                            sda_oe <= ~address_shift[
                                bit_count - 1'b1
                            ];

                            state <= STATE_ADDR_HIGH;

                        end

                    end


                    // =================================================
                    // ADDRESS ACK HIGH
                    // =================================================

                    STATE_ADDR_ACK_HIGH: begin

                        scl <= 1'b1;

                        if (sda_in == 1'b1)

                            ack_error <= 1'b1;

                        state <= STATE_ADDR_ACK_LOW;

                    end


                    // =================================================
                    // ADDRESS ACK LOW
                    // =================================================

                    STATE_ADDR_ACK_LOW: begin

                        scl <= 1'b0;

                        if (ack_error) begin

                            sda_oe <= 1'b1;

                            state <= STATE_STOP_1;

                        end

                        else if (rw) begin

                            // Read operation

                            sda_oe <= 1'b0;

                            bit_count <= 3'd7;

                            state <= STATE_READ_HIGH;

                        end

                        else begin

                            // Write operation

                            sda_oe <= ~tx_shift[7];

                            bit_count <= 3'd7;

                            state <= STATE_DATA_HIGH;

                        end

                    end


                    // =================================================
                    // WRITE DATA HIGH
                    // =================================================

                    STATE_DATA_HIGH: begin

                        scl <= 1'b1;

                        state <= STATE_DATA_LOW;

                    end


                    // =================================================
                    // WRITE DATA LOW
                    // =================================================

                    STATE_DATA_LOW: begin

                        scl <= 1'b0;

                        if (bit_count == 0) begin

                            sda_oe <= 1'b0;

                            state <= STATE_DATA_ACK_HIGH;

                        end

                        else begin

                            bit_count <= bit_count - 1'b1;

                            sda_oe <= ~tx_shift[
                                bit_count - 1'b1
                            ];

                            state <= STATE_DATA_HIGH;

                        end

                    end


                    // =================================================
                    // WRITE DATA ACK HIGH
                    // =================================================

                    STATE_DATA_ACK_HIGH: begin

                        scl <= 1'b1;

                        if (sda_in == 1'b1)

                            ack_error <= 1'b1;

                        state <= STATE_DATA_ACK_LOW;

                    end


                    // =================================================
                    // WRITE DATA ACK LOW
                    // =================================================

                    STATE_DATA_ACK_LOW: begin

                        scl <= 1'b0;

                        sda_oe <= 1'b1;

                        state <= STATE_STOP_1;

                    end


                    // =================================================
                    // READ DATA HIGH
                    // =================================================

                    STATE_READ_HIGH: begin

                        scl <= 1'b1;

                        rx_shift[bit_count] <= sda_in;

                        state <= STATE_READ_LOW;

                    end


                    // =================================================
                    // READ DATA LOW
                    // =================================================

                    STATE_READ_LOW: begin

                        scl <= 1'b0;

                        if (bit_count == 0) begin

                            rx_data <= {
                                rx_shift[7:1],
                                sda_in
                            };

                            // Master ACKs received byte

                            sda_oe <= 1'b1;

                            state <= STATE_READ_ACK_HIGH;

                        end

                        else begin

                            bit_count <= bit_count - 1'b1;

                            sda_oe <= 1'b0;

                            state <= STATE_READ_HIGH;

                        end

                    end


                    // =================================================
                    // READ ACK HIGH
                    // =================================================

                    STATE_READ_ACK_HIGH: begin

                        scl <= 1'b1;

                        state <= STATE_READ_ACK_LOW;

                    end


                    // =================================================
                    // READ ACK LOW
                    // =================================================

                    STATE_READ_ACK_LOW: begin

                        scl <= 1'b0;

                        sda_oe <= 1'b1;

                        state <= STATE_STOP_1;

                    end


                    // =================================================
                    // STOP 1
                    // =================================================

                    STATE_STOP_1: begin

                        scl <= 1'b1;

                        sda_oe <= 1'b1;

                        state <= STATE_STOP_2;

                    end


                    // =================================================
                    // STOP 2
                    // =================================================

                    STATE_STOP_2: begin

                        scl <= 1'b1;

                        // SDA LOW -> HIGH while SCL HIGH

                        sda_oe <= 1'b0;

                        busy <= 1'b0;

                        done <= 1'b1;

                        state <= STATE_IDLE;

                    end


                    // =================================================
                    // DEFAULT
                    // =================================================

                    default: begin

                        state <= STATE_IDLE;

                        scl <= 1'b1;

                        sda_oe <= 1'b0;

                        busy <= 1'b0;

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