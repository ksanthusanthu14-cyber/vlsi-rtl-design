module rom_tb;

reg [3:0] addr;
wire [7:0] data_out;

rom #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(4)
) dut (
    .addr(addr),
    .data_out(data_out)
);

initial begin
    $dumpfile("rom_tb.vcd");
    $dumpvars(0, rom_tb);

    $monitor(
        "Time=%0t | addr=%h | data_out=%h",
        $time,
        addr,
        data_out
    );
end

initial begin

    addr = 4'h0;
    #10;

    addr = 4'h1;
    #10;

    addr = 4'h2;
    #10;

    addr = 4'h3;
    #10;

    addr = 4'h4;
    #10;

    addr = 4'h5;
    #10;

    addr = 4'h6;
    #10;

    addr = 4'h7;
    #10;

    addr = 4'h8;
    #10;

    addr = 4'h9;
    #10;

    addr = 4'hA;
    #10;

    addr = 4'hB;
    #10;

    addr = 4'hC;
    #10;

    addr = 4'hD;
    #10;

    addr = 4'hE;
    #10;

    addr = 4'hF;
    #10;

    $finish;

end

endmodule