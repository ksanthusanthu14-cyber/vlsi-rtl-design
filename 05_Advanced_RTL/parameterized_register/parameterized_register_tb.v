module parameterized_register_tb;

reg clk;
reg rst;
reg load;

reg [15:0] data_in;
wire [15:0] data_out;

parameterized_register #(
    .WIDTH(16)
) dut (
    .clk(clk),
    .rst(rst),
    .load(load),
    .data_in(data_in),
    .data_out(data_out)
);

initial begin
    $dumpfile("parameterized_register_tb.vcd");
    $dumpvars(0, parameterized_register_tb);

    $monitor("Time=%0t | rst=%b | load=%b | data_in=%h | data_out=%h",
             $time, rst, load, data_in, data_out);
end

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    // Reset
    rst = 1;
    load = 0;
    data_in = 8'h00;

    #10;

    // Release reset
    rst = 0;

    // Load first value
    #5;
    load = 1;
    data_in = 8'hA5;

    #10;

    // Hold previous value
    load = 0;
    data_in = 8'h3C;

    #10;

    // Load second value
    load = 1;
    data_in = 8'hF0;

    #10;

    load = 0;

    #10;

    $finish;
end

endmodule