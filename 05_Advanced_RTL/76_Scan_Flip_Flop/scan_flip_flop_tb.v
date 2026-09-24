`timescale 1ns/1ps

module scan_flip_flop_tb;

    reg clk;
    reg rst;
    reg scan_en;
    reg d;
    reg si;

    wire q;

    // ============================================================
    // DUT
    // ============================================================

    scan_flip_flop dut (
        .clk(clk),
        .rst(rst),
        .scan_en(scan_en),
        .d(d),
        .si(si),
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

        $dumpfile("scan_flip_flop.vcd");
        $dumpvars(0, scan_flip_flop_tb);

        rst = 1'b1;
        scan_en = 1'b0;
        d = 1'b0;
        si = 1'b0;

        // --------------------------------------------------------
        // TEST 1: RESET
        // --------------------------------------------------------

        #12;

        if (q === 1'b0)
            $display("PASS: RESET -> Q = 0");
        else
            $display("FAIL: RESET -> Q = %b", q);

        rst = 1'b0;

        // --------------------------------------------------------
        // TEST 2: NORMAL MODE
        // --------------------------------------------------------

        scan_en = 1'b0;
        d = 1'b1;

        @(posedge clk);
        #1;

        if (q === 1'b1)
            $display("PASS: NORMAL MODE D=1 -> Q=1");
        else
            $display("FAIL: NORMAL MODE D=1 -> Q=%b", q);

        // --------------------------------------------------------
        // TEST 3: NORMAL MODE D=0
        // --------------------------------------------------------

        d = 1'b0;

        @(posedge clk);
        #1;

        if (q === 1'b0)
            $display("PASS: NORMAL MODE D=0 -> Q=0");
        else
            $display("FAIL: NORMAL MODE D=0 -> Q=%b", q);

        // --------------------------------------------------------
        // TEST 4: SCAN MODE SHIFT 1
        // --------------------------------------------------------

        scan_en = 1'b1;
        si = 1'b1;

        @(posedge clk);
        #1;

        if (q === 1'b1)
            $display("PASS: SCAN MODE SI=1 -> Q=1");
        else
            $display("FAIL: SCAN MODE SI=1 -> Q=%b", q);

        // --------------------------------------------------------
        // TEST 5: SCAN MODE SHIFT 0
        // --------------------------------------------------------

        si = 1'b0;

        @(posedge clk);
        #1;

        if (q === 1'b0)
            $display("PASS: SCAN MODE SI=0 -> Q=0");
        else
            $display("FAIL: SCAN MODE SI=0 -> Q=%b", q);

        // --------------------------------------------------------
        // TEST 6: SCAN MODE SHIFT 1 AGAIN
        // --------------------------------------------------------

        si = 1'b1;

        @(posedge clk);
        #1;

        if (q === 1'b1)
            $display("PASS: SCAN MODE SI=1 -> Q=1");
        else
            $display("FAIL: SCAN MODE SI=1 -> Q=%b", q);

        // --------------------------------------------------------
        // TEST 7: RETURN TO NORMAL MODE
        // --------------------------------------------------------

        scan_en = 1'b0;
        d = 1'b0;

        @(posedge clk);
        #1;

        if (q === 1'b0)
            $display("PASS: RETURN TO NORMAL MODE -> Q=0");
        else
            $display(
                "FAIL: RETURN TO NORMAL MODE -> Q=%b",
                q
            );

        // --------------------------------------------------------
        // COMPLETE
        // --------------------------------------------------------

        $display("");
        $display("==============================================");
        $display("SCAN FLIP-FLOP VERIFICATION COMPLETE");
        $display("==============================================");

        $finish;

    end

endmodule