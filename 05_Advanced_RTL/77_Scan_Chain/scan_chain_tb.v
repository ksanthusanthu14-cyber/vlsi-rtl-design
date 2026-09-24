`timescale 1ns/1ps

module scan_chain_tb;

    parameter WIDTH = 4;

    reg clk;
    reg rst;
    reg scan_en;

    reg scan_in;
    wire scan_out;

    reg [WIDTH-1:0] d;
    wire [WIDTH-1:0] q;

    // ============================================================
    // DUT
    // ============================================================

    scan_chain #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .scan_en(scan_en),
        .scan_in(scan_in),
        .scan_out(scan_out),
        .d(d),
        .q(q)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ============================================================
    // TEST
    // ============================================================

    initial begin

        $dumpfile("scan_chain.vcd");
        $dumpvars(0, scan_chain_tb);

        rst = 1'b1;
        scan_en = 1'b0;
        scan_in = 1'b0;
        d = 4'b0000;

        // --------------------------------------------------------
        // TEST 1: RESET
        // --------------------------------------------------------

        #12;

        if (q === 4'b0000)
            $display("PASS: RESET -> Q = 0000");
        else
            $display("FAIL: RESET -> Q = %b", q);

        rst = 1'b0;

        // --------------------------------------------------------
        // TEST 2: PARALLEL LOAD
        // --------------------------------------------------------

        scan_en = 1'b0;
        d = 4'b1010;

        @(posedge clk);
        #1;

        if (q === 4'b1010)
            $display("PASS: PARALLEL LOAD -> Q = 1010");
        else
            $display(
                "FAIL: PARALLEL LOAD -> Q = %b",
                q
            );

        // --------------------------------------------------------
        // TEST 3: SCAN SHIFT
        //
        // Starting:
        // Q = 1010
        //
        // Shift in 1
        // Q = 0101
        // --------------------------------------------------------

        scan_en = 1'b1;
        scan_in = 1'b1;

        @(posedge clk);
        #1;

        if (q === 4'b0101)
            $display(
                "PASS: SHIFT IN 1 -> Q = 0101"
            );
        else
            $display(
                "FAIL: SHIFT IN 1 -> Q = %b",
                q
            );

        // --------------------------------------------------------
        // TEST 4
        //
        // Shift in 0
        //
        // 0101 -> 1010
        // --------------------------------------------------------

        scan_in = 1'b0;

        @(posedge clk);
        #1;

        if (q === 4'b1010)
            $display(
                "PASS: SHIFT IN 0 -> Q = 1010"
            );
        else
            $display(
                "FAIL: SHIFT IN 0 -> Q = %b",
                q
            );

        // --------------------------------------------------------
        // TEST 5
        //
        // Shift in 1
        //
        // 1010 -> 0101
        // --------------------------------------------------------

        scan_in = 1'b1;

        @(posedge clk);
        #1;

        if (q === 4'b0101)
            $display(
                "PASS: SHIFT IN 1 -> Q = 0101"
            );
        else
            $display(
                "FAIL: SHIFT IN 1 -> Q = %b",
                q
            );

        // --------------------------------------------------------
        // TEST 6: SHIFT OUT OBSERVATION
        //
        // Current Q = 0101
        // scan_out = Q3 = 0
        // --------------------------------------------------------

        if (scan_out === 1'b0)
            $display(
                "PASS: SCAN OUT = 0"
            );
        else
            $display(
                "FAIL: SCAN OUT = %b",
                scan_out
            );

        // --------------------------------------------------------
        // TEST 7: PARALLEL OPERATION AFTER SCAN
        // --------------------------------------------------------

        scan_en = 1'b0;
        d = 4'b1100;

        @(posedge clk);
        #1;

        if (q === 4'b1100)
            $display(
                "PASS: RETURN TO NORMAL -> Q = 1100"
            );
        else
            $display(
                "FAIL: RETURN TO NORMAL -> Q = %b",
                q
            );

        // --------------------------------------------------------
        // TEST 8: SERIAL PATTERN
        //
        // Start from 0000
        // Shift sequence: 1,0,1,1
        //
        // After shifts:
        //
        // 1 -> 0001
        // 0 -> 0010
        // 1 -> 0101
        // 1 -> 1011
        // --------------------------------------------------------

        scan_en = 1'b0;
        d = 4'b0000;

        @(posedge clk);
        #1;

        scan_en = 1'b1;

        scan_in = 1'b1;

        @(posedge clk);
        #1;

        if (q !== 4'b0001)
            $display(
                "FAIL: SERIAL STEP 1 -> Q = %b",
                q
            );
        else
            $display(
                "PASS: SERIAL STEP 1 -> Q = 0001"
            );

        scan_in = 1'b0;

        @(posedge clk);
        #1;

        if (q !== 4'b0010)
            $display(
                "FAIL: SERIAL STEP 2 -> Q = %b",
                q
            );
        else
            $display(
                "PASS: SERIAL STEP 2 -> Q = 0010"
            );

        scan_in = 1'b1;

        @(posedge clk);
        #1;

        if (q !== 4'b0101)
            $display(
                "FAIL: SERIAL STEP 3 -> Q = %b",
                q
            );
        else
            $display(
                "PASS: SERIAL STEP 3 -> Q = 0101"
            );

        scan_in = 1'b1;

        @(posedge clk);
        #1;

        if (q !== 4'b1011)
            $display(
                "FAIL: SERIAL STEP 4 -> Q = %b",
                q
            );
        else
            $display(
                "PASS: SERIAL STEP 4 -> Q = 1011"
            );

        // --------------------------------------------------------
        // COMPLETE
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("SCAN CHAIN VERIFICATION COMPLETE");
        $display("==============================================");

        $finish;

    end

endmodule