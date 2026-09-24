module single_port_ram_tb;

reg clk;
reg we;

reg [3:0] addr;
reg [7:0] data_in;

wire [7:0] data_out;

single_port_ram #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(4)
) dut (
    .clk(clk),
    .we(we),
    .addr(addr),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    $dumpfile("single_port_ram_tb.vcd");
    $dumpvars(0, single_port_ram_tb);

    $monitor(
        "Time=%0t | we=%b | addr=%h | data_in=%h | data_out=%h",
        $time,
        we,
        addr,
        data_in,
        data_out
    );
end

// Clock
initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    // Initial values
    we = 0;
    addr = 4'h0;
    data_in = 8'h00;

    // -------------------------
    // WRITE ADDRESS 0
    // -------------------------
    #5;
    we = 1;
    addr = 4'h0;
    data_in = 8'hA5;

    #10;

    // -------------------------
    // WRITE ADDRESS 1
    // -------------------------
    addr = 4'h1;
    data_in = 8'h3C;

    #10;

    // -------------------------
    // WRITE ADDRESS 2
    // -------------------------
    addr = 4'h2;
    data_in = 8'hF0;

    #10;

    // -------------------------
    // STOP WRITING
    // -------------------------
    we = 0;

    // READ ADDRESS 0
    addr = 4'h0;

    #10;

    // READ ADDRESS 1
    addr = 4'h1;

    #10;

    // READ ADDRESS 2
    addr = 4'h2;

    #10;

    // READ ADDRESS 3
    // This location was never written.
    addr = 4'h3;

    #10;

    $finish;

end

endmodule