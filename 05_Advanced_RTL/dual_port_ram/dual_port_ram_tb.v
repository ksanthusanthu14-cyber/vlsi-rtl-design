module dual_port_ram_tb;

reg clk_a;
reg clk_b;

reg we_a;
reg we_b;

reg [3:0] addr_a;
reg [3:0] addr_b;

reg [7:0] data_in_a;
reg [7:0] data_in_b;

wire [7:0] data_out_a;
wire [7:0] data_out_b;

dual_port_ram #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(4)
) dut (
    .clk_a(clk_a),
    .we_a(we_a),
    .addr_a(addr_a),
    .data_in_a(data_in_a),
    .data_out_a(data_out_a),

    .clk_b(clk_b),
    .we_b(we_b),
    .addr_b(addr_b),
    .data_in_b(data_in_b),
    .data_out_b(data_out_b)
);

initial begin
    $dumpfile("dual_port_ram_tb.vcd");
    $dumpvars(0, dual_port_ram_tb);

    $monitor(
        "Time=%0t | A: we=%b addr=%h din=%h dout=%h | B: we=%b addr=%h din=%h dout=%h",
        $time,
        we_a,
        addr_a,
        data_in_a,
        data_out_a,
        we_b,
        addr_b,
        data_in_b,
        data_out_b
    );
end

// Port A clock
initial begin
    clk_a = 0;
    forever #5 clk_a = ~clk_a;
end

// Port B clock
initial begin
    clk_b = 0;
    forever #7 clk_b = ~clk_b;
end

initial begin

    // Initial values
    we_a = 0;
    we_b = 0;

    addr_a = 0;
    addr_b = 0;

    data_in_a = 0;
    data_in_b = 0;

    // ========================================
    // PORT A WRITES ADDRESS 0
    // ========================================

    #5;

    we_a = 1;
    addr_a = 4'h0;
    data_in_a = 8'hA5;

    #10;

    // ========================================
    // PORT A WRITES ADDRESS 1
    // ========================================

    addr_a = 4'h1;
    data_in_a = 8'h3C;

    #10;

    // Stop Port A writing
    we_a = 0;

    // ========================================
    // PORT B READS ADDRESS 0
    // ========================================

    addr_b = 4'h0;

    #14;

    // ========================================
    // PORT B READS ADDRESS 1
    // ========================================

    addr_b = 4'h1;

    #14;

    // ========================================
    // PORT B WRITES ADDRESS 2
    // ========================================

    we_b = 1;
    addr_b = 4'h2;
    data_in_b = 8'hF0;

    #14;

    // Stop Port B writing
    we_b = 0;

    // ========================================
    // PORT A READS ADDRESS 2
    // ========================================

    addr_a = 4'h2;

    #20;

    $finish;

end

endmodule