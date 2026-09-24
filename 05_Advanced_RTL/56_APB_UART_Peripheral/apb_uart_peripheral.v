`timescale 1ns/1ps

module apb_uart_peripheral (

    input wire        PCLK,
    input wire        PRESETn,

    // =========================================================
    // APB INTERFACE
    // =========================================================

    input wire        PSEL,
    input wire        PENABLE,
    input wire        PWRITE,
    input wire [7:0]  PADDR,
    input wire [7:0]  PWDATA,

    output reg [7:0]  PRDATA,
    output reg        PREADY,
    output reg        PSLVERR,

    // =========================================================
    // UART INTERFACE
    // =========================================================

    input wire        rx,
    output reg        tx
);


    // =========================================================
    // APB REGISTERS
    // =========================================================

    // 0x00 -> CONTROL
    //          bit 0 = UART enable
    //
    // 0x04 -> STATUS
    //          bit 0 = TX busy
    //          bit 1 = RX data valid
    //
    // 0x08 -> TX DATA
    //
    // 0x0C -> RX DATA
    //
    // 0x10 -> BAUD
    //          clocks per UART bit


    reg [7:0] control_reg;
    reg [7:0] tx_data_reg;
    reg [7:0] rx_data_reg;
    reg [7:0] baud_reg;

    reg       rx_valid;


    // =========================================================
    // UART TX REGISTERS
    // =========================================================

    reg [7:0] tx_shift;
    reg [3:0] tx_bit_count;
    reg [7:0] tx_baud_count;
    reg       tx_busy;


    // =========================================================
    // UART RX REGISTERS
    // =========================================================

    reg [7:0] rx_shift;
    reg [3:0] rx_bit_count;
    reg [7:0] rx_baud_count;
    reg       rx_busy;


    // =========================================================
    // UART TRANSMITTER
    // =========================================================

    always @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn) begin

            tx            <= 1'b1;
            tx_shift      <= 8'h00;
            tx_bit_count  <= 4'd0;
            tx_baud_count <= 8'd0;
            tx_busy       <= 1'b0;

        end else begin

            // -------------------------------------------------
            // TRANSMISSION IN PROGRESS
            // -------------------------------------------------

            if (tx_busy) begin

                if (tx_baud_count >= baud_reg - 1'b1) begin

                    tx_baud_count <= 8'd0;

                    // -------------------------------------------------
                    // SEND DATA BITS
                    // -------------------------------------------------

                    if (tx_bit_count < 8) begin

                        tx <= tx_shift[tx_bit_count];

                        tx_bit_count <= tx_bit_count + 1'b1;

                    end

                    // -------------------------------------------------
                    // SEND STOP BIT
                    // -------------------------------------------------

                    else begin

                        tx <= 1'b1;

                        tx_busy <= 1'b0;

                        tx_bit_count <= 4'd0;

                    end

                end else begin

                    tx_baud_count <= tx_baud_count + 1'b1;

                end

            end

            // -------------------------------------------------
            // START NEW TRANSMISSION
            // -------------------------------------------------

            else if (
                control_reg[0] &&
                PSEL &&
                PENABLE &&
                PWRITE &&
                PADDR == 8'h08
            ) begin

                tx_shift <= PWDATA;

                tx_busy <= 1'b1;

                tx_baud_count <= 8'd0;

                tx_bit_count <= 4'd0;

                // START BIT
                tx <= 1'b0;

            end

        end

    end


    // =========================================================
    // UART RECEIVER
    // =========================================================

    always @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn) begin

            rx_shift      <= 8'h00;
            rx_bit_count  <= 4'd0;
            rx_baud_count <= 8'd0;

            rx_busy       <= 1'b0;

            rx_valid      <= 1'b0;

            rx_data_reg   <= 8'h00;

        end else begin

            // rx_valid is a one-clock pulse
            rx_valid <= 1'b0;


            // =================================================
            // DETECT START BIT
            // =================================================

            if (!rx_busy && !rx && control_reg[0]) begin

                rx_busy <= 1'b1;

                rx_bit_count <= 4'd0;

                rx_shift <= 8'h00;

                /*
                 * The start bit has just been detected.
                 *
                 * We need to wait:
                 *
                 *       1 full bit
                 *          +
                 *       half bit
                 *
                 * before sampling DATA BIT 0.
                 *
                 * Therefore:
                 *
                 * baud + baud/2 - 1
                 */

                rx_baud_count <=
                    baud_reg + (baud_reg >> 1) - 1'b1;

            end


            // =================================================
            // RECEIVE UART FRAME
            // =================================================

            else if (rx_busy) begin

                if (rx_baud_count == 0) begin

                    // -----------------------------------------
                    // DATA BITS
                    // -----------------------------------------

                    if (rx_bit_count < 8) begin

                        rx_shift[rx_bit_count] <= rx;

                        rx_bit_count <=
                            rx_bit_count + 1'b1;

                        // Next data bit after one full bit period
                        rx_baud_count <= baud_reg - 1'b1;

                    end

                    // -----------------------------------------
                    // STOP BIT
                    // -----------------------------------------

                    else begin

                        rx_busy <= 1'b0;

                        rx_data_reg <= rx_shift;

                        rx_valid <= 1'b1;

                        rx_baud_count <= 8'd0;

                    end

                end else begin

                    rx_baud_count <= rx_baud_count - 1'b1;

                end

            end

        end

    end


    // =========================================================
    // APB INTERFACE
    // =========================================================

    always @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn) begin

            control_reg <= 8'h00;

            tx_data_reg <= 8'h00;

            rx_data_reg <= 8'h00;

            baud_reg <= 8'h04;

            PRDATA <= 8'h00;

            PREADY <= 1'b0;

            PSLVERR <= 1'b0;

        end else begin

            PREADY <= 1'b0;

            PSLVERR <= 1'b0;


            // =================================================
            // APB ACCESS PHASE
            // =================================================

            if (PSEL && PENABLE) begin

                PREADY <= 1'b1;


                // =================================================
                // WRITE
                // =================================================

                if (PWRITE) begin

                    case (PADDR)

                        // CONTROL
                        8'h00: begin

                            control_reg <= PWDATA;

                        end


                        // TX DATA
                        8'h08: begin

                            tx_data_reg <= PWDATA;

                        end


                        // BAUD
                        8'h10: begin

                            baud_reg <= PWDATA;

                        end


                        // STATUS and RX DATA are read-only
                        8'h04,
                        8'h0C: begin

                            PSLVERR <= 1'b1;

                        end


                        // INVALID ADDRESS
                        default: begin

                            PSLVERR <= 1'b1;

                        end

                    endcase

                end


                // =================================================
                // READ
                // =================================================

                else begin

                    case (PADDR)

                        // CONTROL
                        8'h00: begin

                            PRDATA <= control_reg;

                        end


                        // STATUS
                        8'h04: begin

                            PRDATA[0] <= tx_busy;

                            PRDATA[1] <= rx_valid;

                            PRDATA[7:2] <= 6'b000000;

                        end


                        // TX DATA
                        8'h08: begin

                            PRDATA <= tx_data_reg;

                        end


                        // RX DATA
                        8'h0C: begin

                            PRDATA <= rx_data_reg;

                        end


                        // BAUD
                        8'h10: begin

                            PRDATA <= baud_reg;

                        end


                        // INVALID ADDRESS
                        default: begin

                            PRDATA <= 8'h00;

                            PSLVERR <= 1'b1;

                        end

                    endcase

                end

            end

        end

    end

endmodule