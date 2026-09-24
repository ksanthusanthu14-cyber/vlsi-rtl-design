module synchronous_fifo_tb;

reg clk;
reg rst;

reg write_en;
reg read_en;

reg [7:0] data_in;
wire [7:0] data_out;

wire full;
wire empty;

synchronous_fifo #(
    .DATA_WIDTH(8),
    .DEPTH(8)
) dut (
    .clk(clk),
    .rst(rst),

    .write_en(write_en),
    .read_en(read_en),

    .data_in(data_in),
    .data_out(data_out),

    .full(full),
    .empty(empty)
);

initial begin

    $dumpfile("synchronous_fifo_tb.vcd");
    $dumpvars(0, synchronous_fifo_tb);

    $monitor(
        "Time=%0t | WE=%b | RE=%b | DIN=%h | DOUT=%h | FULL=%b | EMPTY=%b | COUNT=%0d",
        $time,
        write_en,
        read_en,
        data_in,
        data_out,
        full,
        empty,
        dut.count
    );

end

// Clock
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    // Initial state
    rst = 1;
    write_en = 0;
    read_en = 0;
    data_in = 8'h00;

    #10;

    rst = 0;

    // ========================================
    // WRITE A1
    // ========================================

    #5;
    write_en = 1;
    data_in = 8'hA1;

    #10;

    // ========================================
    // WRITE B2
    // ========================================

    data_in = 8'hB2;

    #10;

    // ========================================
    // WRITE C3
    // ========================================

    data_in = 8'hC3;

    #10;

    // ========================================
    // WRITE D4
    // ========================================

    data_in = 8'hD4;

    #10;

    // Stop writing
    write_en = 0;

    // ========================================
    // READ A1
    // ========================================

    read_en = 1;

    #10;

    // ========================================
    // READ B2
    // ========================================

    #10;

    // ========================================
    // READ C3
    // ========================================

    #10;

    // ========================================
    // READ D4
    // ========================================

    #10;

    read_en = 0;

    #20;

    $finish;

end

endmodule