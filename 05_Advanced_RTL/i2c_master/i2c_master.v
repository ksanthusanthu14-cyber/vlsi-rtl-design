`timescale 1ns/1ps

module i2c_master #(
    parameter CLK_DIV = 4
)(
    input  wire       clk,
    input  wire       rst,

    input  wire       start,
    input  wire [6:0] slave_addr,
    input  wire [7:0] tx_data,

    input  wire       sda_in,

    output reg        scl,
    output reg        sda_out,
    output reg        sda_oe,

    output reg        busy,
    output reg        done,
    output reg        ack_error
);

    localparam IDLE     = 4'd0;
    localparam START    = 4'd1;
    localparam ADDR     = 4'd2;
    localparam ADDR_ACK = 4'd3;
    localparam DATA     = 4'd4;
    localparam DATA_ACK = 4'd5;
    localparam STOP_1   = 4'd6;
    localparam STOP_2   = 4'd7;

    reg [3:0] state;

    reg [7:0] shift_reg;
    reg [3:0] bit_count;

    reg [31:0] clk_count;

    wire tick;

    assign tick = (clk_count == CLK_DIV-1);


    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state      <= IDLE;

            scl        <= 1'b1;
            sda_out    <= 1'b1;
            sda_oe     <= 1'b0;

            busy       <= 1'b0;
            done       <= 1'b0;
            ack_error  <= 1'b0;

            shift_reg  <= 8'h00;
            bit_count  <= 4'd0;

            clk_count  <= 32'd0;

        end

        else begin

            done <= 1'b0;

            if (tick)
                clk_count <= 32'd0;
            else
                clk_count <= clk_count + 1'b1;


            if (tick) begin

                case (state)

                    // =================================================
                    // IDLE
                    // =================================================

                    IDLE: begin

                        scl       <= 1'b1;
                        sda_out   <= 1'b1;
                        sda_oe    <= 1'b0;

                        busy      <= 1'b0;
                        ack_error <= 1'b0;

                        if (start) begin

                            busy <= 1'b1;

                            // Address + WRITE bit
                            shift_reg <= {
                                slave_addr,
                                1'b0
                            };

                            bit_count <= 4'd7;

                            state <= START;

                        end

                    end


                    // =================================================
                    // START
                    // SDA goes LOW while SCL is HIGH
                    // =================================================

                    START: begin

                        scl     <= 1'b1;
                        sda_oe  <= 1'b1;
                        sda_out <= 1'b0;

                        state <= ADDR;

                    end


                    // =================================================
                    // ADDRESS
                    // =================================================

                    ADDR: begin

                        if (scl == 1'b1) begin

                            // Put bit on SDA while SCL is LOW
                            scl <= 1'b0;

                            sda_oe  <= 1'b1;
                            sda_out <= shift_reg[7];

                        end

                        else begin

                            // Sample/hold bit while SCL HIGH
                            scl <= 1'b1;

                            if (bit_count == 0) begin

                                // Release SDA for ACK
                                sda_oe <= 1'b0;

                                state <= ADDR_ACK;

                            end

                            else begin

                                shift_reg <= {
                                    shift_reg[6:0],
                                    1'b0
                                };

                                bit_count <= bit_count - 1'b1;

                            end

                        end

                    end


                    // =================================================
                    // ADDRESS ACK
                    // =================================================

                    ADDR_ACK: begin

                        // SCL is currently HIGH.
                        // Slave must pull SDA LOW for ACK.

                        if (sda_in != 1'b0)
                            ack_error <= 1'b1;

                        scl <= 1'b0;

                        shift_reg <= tx_data;
                        bit_count <= 4'd7;

                        state <= DATA;

                    end


                    // =================================================
                    // DATA
                    // =================================================

                    DATA: begin

                        if (scl == 1'b0) begin

                            // Put data bit on SDA
                            sda_oe  <= 1'b1;
                            sda_out <= shift_reg[7];

                            scl <= 1'b1;

                        end

                        else begin

                            // Finish HIGH phase
                            scl <= 1'b0;

                            if (bit_count == 0) begin

                                // Release SDA for ACK
                                sda_oe <= 1'b0;

                                state <= DATA_ACK;

                            end

                            else begin

                                shift_reg <= {
                                    shift_reg[6:0],
                                    1'b0
                                };

                                bit_count <= bit_count - 1'b1;

                            end

                        end

                    end


                    // =================================================
                    // DATA ACK
                    // =================================================

                    DATA_ACK: begin

                        // SCL is LOW here.
                        // Raise SCL to sample ACK.

                        scl <= 1'b1;

                        state <= STOP_1;

                        if (sda_in != 1'b0)
                            ack_error <= 1'b1;

                    end


                    // =================================================
                    // STOP - prepare
                    // =================================================

                    STOP_1: begin

                        // SCL remains HIGH.
                        // SDA currently LOW.

                        scl     <= 1'b1;
                        sda_oe  <= 1'b1;
                        sda_out <= 1'b0;

                        state <= STOP_2;

                    end


                    // =================================================
                    // STOP
                    // SDA LOW -> HIGH while SCL HIGH
                    // =================================================

                    STOP_2: begin

                        scl     <= 1'b1;

                        sda_oe  <= 1'b0;
                        sda_out <= 1'b1;

                        busy <= 1'b0;
                        done <= 1'b1;

                        state <= IDLE;

                    end


                    default: begin

                        state <= IDLE;

                    end

                endcase

            end

        end

    end

endmodule