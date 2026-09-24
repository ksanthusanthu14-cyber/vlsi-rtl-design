module complete_uart_tb;

reg clk;
reg rst;

reg tx_start;
reg [7:0] tx_data;

wire tx;
wire tx_busy;
wire tx_done;

wire [7:0] rx_data;
wire rx_valid;
wire rx_busy;

complete_uart #(
    .DATA_WIDTH(8),
    .CLKS_PER_BIT(4)
) dut (
    .clk(clk),
    .rst(rst),

    .tx_start(tx_start),
    .tx_data(tx_data),

    .tx(tx),
    .tx_busy(tx_busy),
    .tx_done(tx_done),

    .rx_data(rx_data),
    .rx_valid(rx_valid),
    .rx_busy(rx_busy)
);


// ============================================================
// CLOCK
// ============================================================

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end


// ============================================================
// WAVEFORM
// ============================================================

initial begin

    $dumpfile("complete_uart_tb.vcd");
    $dumpvars(0, complete_uart_tb);

    $monitor(
        "Time=%0t | TX_START=%b | TX_DATA=%h | TX=%b | TX_BUSY=%b | TX_DONE=%b | RX_DATA=%h | RX_VALID=%b | RX_BUSY=%b",
        $time,
        tx_start,
        tx_data,
        tx,
        tx_busy,
        tx_done,
        rx_data,
        rx_valid,
        rx_busy
    );

end


// ============================================================
// TEST
// ============================================================

initial begin

    rst = 1;

    tx_start = 0;
    tx_data = 8'h00;

    #20;

    rst = 0;

    // ========================================================
    // TRANSMIT A5
    // ========================================================

    #20;

    tx_data = 8'hA5;
    tx_start = 1;

    #10;

    tx_start = 0;

    // Wait for complete UART frame
    #500;

    // ========================================================
    // TRANSMIT 3C
    // ========================================================

    tx_data = 8'h3C;
    tx_start = 1;

    #10;

    tx_start = 0;

    #500;

    // ========================================================
    // TRANSMIT F0
    // ========================================================

    tx_data = 8'hF0;
    tx_start = 1;

    #10;

    tx_start = 0;

    #500;

    $finish;

end

endmodule