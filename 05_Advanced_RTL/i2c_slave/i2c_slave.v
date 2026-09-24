`timescale 1ns/1ps

module i2c_slave #(
    parameter [6:0] SLAVE_ADDR = 7'h50
)(
    input  wire       rst,

    input  wire       scl,
    input  wire       sda_in,

    output reg        sda_out,
    output reg        sda_oe,

    input  wire [7:0] tx_data,

    output reg [7:0] rx_data,
    output reg       data_valid,
    output reg       read_request
);

    // =========================================================
    // STATE DEFINITIONS
    // =========================================================

    localparam IDLE      = 3'd0;
    localparam ADDRESS   = 3'd1;
    localparam ADDR_ACK  = 3'd2;
    localparam RECEIVE   = 3'd3;
    localparam RX_ACK    = 3'd4;
    localparam TRANSMIT  = 3'd5;
    localparam TX_ACK    = 3'd6;


    // =========================================================
    // INTERNAL REGISTERS
    // =========================================================

    reg [2:0] state;

    reg [7:0] shift_reg;

    reg [3:0] bit_count;

    reg [6:0] address_reg;

    reg       rw_reg;


    // =========================================================
    // RESET
    // =========================================================

    always @(posedge rst) begin

        state        = IDLE;

        shift_reg    = 8'h00;

        bit_count    = 4'd7;

        address_reg  = 7'h00;

        rw_reg       = 1'b0;

        rx_data      = 8'h00;

        data_valid   = 1'b0;

        read_request = 1'b0;

        sda_out      = 1'b1;

        sda_oe       = 1'b0;

    end


    // =========================================================
    // START CONDITION
    //
    // SDA: HIGH -> LOW
    // while SCL is HIGH
    // =========================================================

    always @(negedge sda_in) begin

        if (!rst && scl) begin

            state = ADDRESS;

            shift_reg = 8'h00;

            bit_count = 4'd7;

            data_valid = 1'b0;

            read_request = 1'b0;

            sda_oe = 1'b0;

            sda_out = 1'b1;

        end

    end


    // =========================================================
    // STOP CONDITION
    //
    // SDA: LOW -> HIGH
    // while SCL is HIGH
    // =========================================================

    always @(posedge sda_in) begin

        if (!rst && scl) begin

            state = IDLE;

            bit_count = 4'd7;

            sda_oe = 1'b0;

            sda_out = 1'b1;

        end

    end


    // =========================================================
    // RECEIVE / TRANSMIT LOGIC
    //
    // I2C samples incoming data on SCL rising edge.
    // =========================================================

    always @(posedge scl) begin

        if (!rst) begin

            case (state)

                // =================================================
                // ADDRESS RECEPTION
                //
                // 8-bit byte:
                //
                // [7:1] = 7-bit slave address
                // [0]   = R/W
                //
                // Example:
                //
                // 50 + WRITE = A0
                // 50 + READ  = A1
                // =================================================

                ADDRESS: begin

                    shift_reg = {
                        shift_reg[6:0],
                        sda_in
                    };

                    if (bit_count == 0) begin

                        address_reg = shift_reg[7:1];

                        rw_reg = shift_reg[0];

                        bit_count = 4'd7;

                        state = ADDR_ACK;

                    end

                    else begin

                        bit_count = bit_count - 1'b1;

                    end

                end


                // =================================================
                // ADDRESS ACK PHASE
                // =================================================

                ADDR_ACK: begin

                    if (address_reg == SLAVE_ADDR) begin

                        // -------------------------------------------------
                        // WRITE
                        // -------------------------------------------------

                        if (rw_reg == 1'b0) begin

                            bit_count = 4'd7;

                            state = RECEIVE;

                        end

                        // -------------------------------------------------
                        // READ
                        // -------------------------------------------------

                        else begin

                            shift_reg = tx_data;

                            bit_count = 4'd7;

                            read_request = 1'b1;

                            state = TRANSMIT;

                        end

                    end

                    else begin

                        // Address mismatch

                        state = IDLE;

                    end

                end


                // =================================================
                // RECEIVE DATA FROM MASTER
                // =================================================

                RECEIVE: begin

                    shift_reg = {
                        shift_reg[6:0],
                        sda_in
                    };

                    if (bit_count == 0) begin

                        // The final bit has already entered
                        // shift_reg.

                        rx_data = {
                            shift_reg[6:0],
                            sda_in
                        };

                        data_valid = 1'b1;

                        bit_count = 4'd7;

                        state = RX_ACK;

                    end

                    else begin

                        bit_count = bit_count - 1'b1;

                    end

                end


                // =================================================
                // RECEIVE ACK COMPLETE
                // =================================================

                RX_ACK: begin

                    // Master has completed the ACK clock.

                    state = IDLE;

                    bit_count = 4'd7;

                end


                // =================================================
                // TRANSMIT DATA TO MASTER
                // =================================================

                TRANSMIT: begin

                    if (bit_count == 0) begin

                        // All 8 bits transmitted

                        state = TX_ACK;

                    end

                    else begin

                        // Shift next bit toward MSB position

                        shift_reg = {
                            shift_reg[6:0],
                            1'b0
                        };

                        bit_count = bit_count - 1'b1;

                    end

                end


                // =================================================
                // MASTER ACK/NACK
                // =================================================

                TX_ACK: begin

                    state = IDLE;

                    bit_count = 4'd7;

                end


                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    state = IDLE;

                    bit_count = 4'd7;

                end

            endcase

        end

    end


    // =========================================================
    // SDA OUTPUT LOGIC
    //
    // SDA is changed while SCL is LOW.
    //
    // I2C uses OPEN-DRAIN signaling:
    //
    // To transmit 0:
    //     pull SDA LOW
    //
    // To transmit 1:
    //     release SDA
    // =========================================================

    always @(negedge scl) begin

        if (!rst) begin

            case (state)

                // =================================================
                // ADDRESS ACK
                // =================================================

                ADDR_ACK: begin

                    if (address_reg == SLAVE_ADDR) begin

                        // ACK = LOW

                        sda_oe  = 1'b1;

                        sda_out = 1'b0;

                    end

                    else begin

                        // NACK / release bus

                        sda_oe  = 1'b0;

                        sda_out = 1'b1;

                    end

                end


                // =================================================
                // RECEIVE ACK
                // =================================================

                RX_ACK: begin

                    // ACK = LOW

                    sda_oe  = 1'b1;

                    sda_out = 1'b0;

                end


                // =================================================
                // TRANSMIT DATA
                // =================================================

                TRANSMIT: begin

                    if (shift_reg[7] == 1'b0) begin

                        // -----------------------------------------
                        // Transmit 0
                        // -----------------------------------------

                        sda_oe  = 1'b1;

                        sda_out = 1'b0;

                    end

                    else begin

                        // -----------------------------------------
                        // Transmit 1
                        //
                        // Release SDA.
                        // External pull-up makes SDA HIGH.
                        // -----------------------------------------

                        sda_oe  = 1'b0;

                        sda_out = 1'b1;

                    end

                end


                // =================================================
                // MASTER ACK/NACK
                // =================================================

                TX_ACK: begin

                    // Release SDA so master can ACK/NACK.

                    sda_oe  = 1'b0;

                    sda_out = 1'b1;

                end


                // =================================================
                // IDLE
                // =================================================

                default: begin

                    sda_oe  = 1'b0;

                    sda_out = 1'b1;

                end

            endcase

        end

    end

endmodule