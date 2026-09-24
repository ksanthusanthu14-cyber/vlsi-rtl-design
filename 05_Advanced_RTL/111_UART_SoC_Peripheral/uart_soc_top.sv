`timescale 1ns/1ps

module uart_soc_top #(
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

    // UART pins
    output logic        uart_tx,
    input  logic        uart_rx
);

    apb_uart #(
        .CLK_PER_BIT(CLK_PER_BIT)
    ) u_apb_uart (
        .clk      (clk),
        .rst      (rst),

        .psel     (psel),
        .penable  (penable),
        .pwrite   (pwrite),
        .paddr    (paddr),
        .pwdata   (pwdata),

        .prdata   (prdata),
        .pready   (pready),

        .uart_tx  (uart_tx),
        .uart_rx  (uart_rx)
    );

endmodule