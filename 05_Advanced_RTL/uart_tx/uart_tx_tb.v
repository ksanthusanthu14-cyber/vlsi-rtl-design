module uart_tx_tb;

reg clk;
reg rst;

reg tx_start;
reg [7:0] tx_data;

wire tx;
wire busy;
wire done;

uart_tx #(
    .DATA_WIDTH(8),
    .CLKS_PER_BIT(4)
) dut (
    .clk(clk),
    .rst(rst),

    .tx_start(tx_start),
    .tx_data(tx_data),

    .tx(tx),
    .busy(busy),
    .done(done)
);

// ------------------------------------------------
// Clock
// ------------------------------------------------

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// ------------------------------------------------
// Waveform
// ------------------------------------------------

initial begin

    $dumpfile("uart_tx_tb.vcd");
    $dumpvars(0, uart_tx_tb);

    $monitor(
        "Time=%0t | start=%b | data=%h | tx=%b | busy=%b | done=%b | state=%0d | bit=%0d | baud_count=%0d",
        $time,
        tx_start,
        tx_data,
        tx,
        busy,
        done,
        dut.state,
        dut.bit_index,
        dut.baud_counter
    );

end

// ------------------------------------------------
// Test
// ------------------------------------------------

initial begin

    rst = 1;
    tx_start = 0;
    tx_data = 8'h00;

    #20;

    rst = 0;

    // --------------------------------------------
    // Transmit 0xA5
    // --------------------------------------------

    #10;

    tx_data = 8'hA5;
    tx_start = 1;

    #10;

    tx_start = 0;

    // Wait for complete frame
    #220;

    // --------------------------------------------
    // Transmit 0x3C
    // --------------------------------------------

    tx_data = 8'h3C;
    tx_start = 1;

    #10;

    tx_start = 0;

    #220;

    $finish;

end

endmodule