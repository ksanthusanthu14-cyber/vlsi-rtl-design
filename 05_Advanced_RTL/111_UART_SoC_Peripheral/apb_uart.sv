`timescale 1ns/1ps

module apb_uart #(
    parameter integer CLK_PER_BIT = 4
)(
    input  logic        clk,
    input  logic        rst,

    // APB interface
    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    input  logic [7:0]  paddr,
    input  logic [31:0] pwdata,

    output logic [31:0] prdata,
    output logic        pready,

    // UART
    output logic        uart_tx,
    input  logic        uart_rx
);

    logic [7:0] tx_data;
    logic [7:0] rx_data;

    logic tx_start;
    logic tx_busy;
    logic tx_done;

    logic rx_valid;
    logic rx_error;

    logic [31:0] control_reg;

    logic apb_write;

    assign apb_write = psel && penable && pwrite;

    assign pready = psel && penable;

    uart_tx #(
        .CLK_PER_BIT(CLK_PER_BIT)
    ) u_uart_tx (
        .clk      (clk),
        .rst      (rst),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .tx       (uart_tx),
        .busy     (tx_busy),
        .done     (tx_done)
    );

    uart_rx #(
        .CLK_PER_BIT(CLK_PER_BIT)
    ) u_uart_rx (
        .clk      (clk),
        .rst      (rst),
        .rx       (uart_rx),
        .rx_data  (rx_data),
        .rx_valid (rx_valid),
        .rx_error (rx_error)
    );

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            tx_data    <= 8'h00;
            control_reg <= 32'h00000000;
            tx_start   <= 1'b0;
        end

        else begin

            tx_start <= 1'b0;

            if (apb_write) begin

                case (paddr)

                    8'h00: begin
                        tx_data  <= pwdata[7:0];
                        tx_start <= 1'b1;
                    end

                    8'h08: begin
                        control_reg <= pwdata;
                    end

                    default: begin
                    end

                endcase

            end
        end
    end

    always_comb begin

        prdata = 32'h00000000;

        if (psel && penable && !pwrite) begin

            case (paddr)

                8'h00: begin
                    prdata = {24'h000000, rx_data};
                end

                8'h04: begin
                    prdata = {
                        28'h0000000,
                        rx_error,
                        rx_valid,
                        tx_done,
                        tx_busy
                    };
                end

                8'h08: begin
                    prdata = control_reg;
                end

                default: begin
                    prdata = 32'h00000000;
                end

            endcase
        end
    end

endmodule