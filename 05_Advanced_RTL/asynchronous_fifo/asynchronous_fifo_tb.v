module asynchronous_fifo_tb;

reg wr_clk;
reg rd_clk;

reg wr_rst;
reg rd_rst;

reg wr_en;
reg rd_en;

reg [7:0] wr_data;

wire [7:0] rd_data;

wire full;
wire empty;

asynchronous_fifo #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(3)
) dut (
    .wr_clk(wr_clk),
    .wr_rst(wr_rst),
    .wr_en(wr_en),
    .wr_data(wr_data),
    .full(full),

    .rd_clk(rd_clk),
    .rd_rst(rd_rst),
    .rd_en(rd_en),
    .rd_data(rd_data),
    .empty(empty)
);

// ------------------------------------------------------------
// WRITE CLOCK
// ------------------------------------------------------------

initial begin
    wr_clk = 0;
    forever #5 wr_clk = ~wr_clk;
end

// ------------------------------------------------------------
// READ CLOCK
// ------------------------------------------------------------

initial begin
    rd_clk = 0;
    forever #7 rd_clk = ~rd_clk;
end

// ------------------------------------------------------------
// MONITOR
// ------------------------------------------------------------

initial begin

    $dumpfile("asynchronous_fifo_tb.vcd");
    $dumpvars(0, asynchronous_fifo_tb);

    $monitor(
        "Time=%0t | WR_EN=%b WR_DATA=%h FULL=%b | RD_EN=%b RD_DATA=%h EMPTY=%b",
        $time,
        wr_en,
        wr_data,
        full,
        rd_en,
        rd_data,
        empty
    );

end

// ------------------------------------------------------------
// TEST
// ------------------------------------------------------------

initial begin

    wr_rst = 1;
    rd_rst = 1;

    wr_en = 0;
    rd_en = 0;

    wr_data = 8'h00;

    #20;

    wr_rst = 0;
    rd_rst = 0;

    // ========================================================
    // WRITE DATA
    // ========================================================

    #10;

    wr_en = 1;
    wr_data = 8'hA1;

    #10;
    wr_data = 8'hB2;

    #10;
    wr_data = 8'hC3;

    #10;
    wr_data = 8'hD4;

    #10;
    wr_data = 8'hE5;

    #10;
    wr_data = 8'hF6;

    #10;
    wr_data = 8'h17;

    #10;
    wr_data = 8'h28;

    #10;

    wr_en = 0;

    // Allow synchronization
    #30;

    // ========================================================
    // READ DATA
    // ========================================================

    rd_en = 1;

    #14;
    #14;
    #14;
    #14;
    #14;
    #14;
    #14;
    #14;

    rd_en = 0;

    #30;

    $finish;

end

endmodule