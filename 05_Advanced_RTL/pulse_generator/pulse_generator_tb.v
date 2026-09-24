module pulse_generator_tb;

reg clk;
reg rst;
reg trigger;

wire pulse;

pulse_generator #(
    .PULSE_WIDTH(4)
) dut (
    .clk(clk),
    .rst(rst),
    .trigger(trigger),
    .pulse(pulse)
);

initial begin
    $dumpfile("pulse_generator_tb.vcd");
    $dumpvars(0, pulse_generator_tb);

    $monitor(
        "Time=%0t | rst=%b | trigger=%b | pulse=%b | counter=%0d",
        $time,
        rst,
        trigger,
        pulse,
        dut.counter
    );
end

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin

    // Reset
    rst = 1;
    trigger = 0;

    #10;

    rst = 0;

    // First trigger
    #10;
    trigger = 1;

    #10;
    trigger = 0;

    // Wait
    #50;

    // Second trigger
    trigger = 1;

    #10;
    trigger = 0;

    #60;

    $finish;

end

endmodule