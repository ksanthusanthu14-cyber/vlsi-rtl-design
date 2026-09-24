`timescale 1ns/1ps

module apb_uart_simple #(
    parameter integer CLK_PER_BIT = 4
)(
    input  logic        clk,
    input  logic        rst,

    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    input  logic [7:0]  paddr,
    input  logic [31:0] pwdata,

    output logic [31:0] prdata,
    output logic        pready,

    output logic        uart_tx
);

    logic [7:0] tx_data;
    logic       tx_start;
    logic       tx_busy;
    logic       tx_done;

    logic [3:0] bit_count;
    integer baud_count;

    assign pready = psel && penable;

    // ------------------------------------------------------------
    // UART TRANSMITTER
    // ------------------------------------------------------------

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            tx_data    <= 8'h00;
            tx_start   <= 1'b0;
            tx_busy    <= 1'b0;
            tx_done    <= 1'b0;
            bit_count  <= 4'd0;
            baud_count <= 0;
            uart_tx    <= 1'b1;
        end

        else begin

            tx_start <= 1'b0;
            tx_done  <= 1'b0;

            // APB write to DATA register
            if (psel && penable && pwrite && (paddr == 8'h00)) begin

                if (!tx_busy) begin
                    tx_data    <= pwdata[7:0];
                    tx_start   <= 1'b1;
                    tx_busy    <= 1'b1;
                    bit_count  <= 4'd0;
                    baud_count <= 0;
                    uart_tx    <= 1'b0;
                end

            end

            // UART transmission
            if (tx_busy) begin

                if (baud_count == CLK_PER_BIT-1) begin

                    baud_count <= 0;

                    if (bit_count < 4'd8) begin

                        bit_count <= bit_count + 1'b1;

                        if (bit_count == 4'd7)
                            uart_tx <= 1'b1;
                        else
                            uart_tx <= tx_data[bit_count + 1'b1];

                    end

                    else begin

                        tx_busy  <= 1'b0;
                        tx_done  <= 1'b1;
                        uart_tx  <= 1'b1;
                        bit_count <= 4'd0;

                    end

                end
                else begin
                    baud_count <= baud_count + 1;
                end

            end

        end

    end


    // ------------------------------------------------------------
    // APB READ
    // ------------------------------------------------------------

    always_comb begin

        prdata = 32'h00000000;

        if (psel && penable && !pwrite) begin

            case (paddr)

                8'h00:
                    prdata = {24'h000000, tx_data};

                8'h04:
                    prdata = {
                        30'h00000000,
                        tx_done,
                        tx_busy
                    };

                default:
                    prdata = 32'h00000000;

            endcase

        end

    end

endmodule