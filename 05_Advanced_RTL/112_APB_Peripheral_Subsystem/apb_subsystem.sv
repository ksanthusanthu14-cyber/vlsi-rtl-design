`timescale 1ns/1ps

module apb_subsystem #(
    parameter integer UART_CLK_PER_BIT = 4
)(
    input  logic        clk,
    input  logic        rst,

    // ------------------------------------------------------------
    // APB MASTER INTERFACE
    // ------------------------------------------------------------

    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    input  logic [11:0] paddr,
    input  logic [31:0] pwdata,

    output logic [31:0] prdata,
    output logic        pready,

    // ------------------------------------------------------------
    // PERIPHERAL OUTPUTS
    // ------------------------------------------------------------

    output logic        uart_tx,
    output logic [7:0]  gpio_out
);

    // ------------------------------------------------------------
    // ADDRESS DECODE
    //
    // UART  : 0x000 - 0x0FF
    // TIMER : 0x100 - 0x1FF
    // GPIO  : 0x200 - 0x2FF
    // ------------------------------------------------------------

    logic uart_sel;
    logic timer_sel;
    logic gpio_sel;

    logic [31:0] uart_prdata;
    logic [31:0] timer_prdata;
    logic [31:0] gpio_prdata;

    logic uart_ready;
    logic timer_ready;
    logic gpio_ready;


    assign uart_sel  = psel && (paddr[11:8] == 4'h0);
    assign timer_sel = psel && (paddr[11:8] == 4'h1);
    assign gpio_sel  = psel && (paddr[11:8] == 4'h2);


    // ------------------------------------------------------------
    // UART
    // ------------------------------------------------------------

    apb_uart_simple #(
        .CLK_PER_BIT(UART_CLK_PER_BIT)
    ) u_uart (
        .clk     (clk),
        .rst     (rst),

        .psel    (uart_sel),
        .penable (penable),
        .pwrite  (pwrite),
        .paddr   (paddr[7:0]),
        .pwdata  (pwdata),

        .prdata  (uart_prdata),
        .pready  (uart_ready),

        .uart_tx (uart_tx)
    );


    // ------------------------------------------------------------
    // TIMER
    // ------------------------------------------------------------

    apb_timer u_timer (

        .clk     (clk),
        .rst     (rst),

        .psel    (timer_sel),
        .penable (penable),
        .pwrite  (pwrite),
        .paddr   (paddr[7:0]),
        .pwdata  (pwdata),

        .prdata  (timer_prdata),
        .pready  (timer_ready)

    );


    // ------------------------------------------------------------
    // GPIO
    // ------------------------------------------------------------

    apb_gpio u_gpio (

        .clk     (clk),
        .rst     (rst),

        .psel    (gpio_sel),
        .penable (penable),
        .pwrite  (pwrite),
        .paddr   (paddr[7:0]),
        .pwdata  (pwdata),

        .prdata  (gpio_prdata),
        .pready  (gpio_ready),

        .gpio_out (gpio_out)

    );


    // ------------------------------------------------------------
    // RESPONSE MUX
    // ------------------------------------------------------------

    always_comb begin

        prdata = 32'h00000000;
        pready = 1'b0;

        if (uart_sel) begin
            prdata = uart_prdata;
            pready = uart_ready;
        end

        else if (timer_sel) begin
            prdata = timer_prdata;
            pready = timer_ready;
        end

        else if (gpio_sel) begin
            prdata = gpio_prdata;
            pready = gpio_ready;
        end

        else begin
            prdata = 32'h00000000;
            pready = 1'b0;
        end

    end

endmodule