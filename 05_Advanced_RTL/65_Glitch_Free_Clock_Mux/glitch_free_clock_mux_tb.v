`timescale 1ns/1ps

module glitch_free_clock_mux_tb;

    reg clk0;
    reg clk1;
    reg select;
    reg rst;

    wire clk_out;

    integer errors;
    integer rising_edges;


    // =========================================================
    // DUT
    // =========================================================

    glitch_free_clock_mux dut (
        .clk0(clk0),
        .clk1(clk1),
        .select(select),
        .rst(rst),
        .clk_out(clk_out)
    );


    // =========================================================
    // CLOCK 0
    // 10 ns PERIOD
    // =========================================================

    initial begin

        clk0 = 1'b0;

        forever #5 clk0 = ~clk0;

    end


    // =========================================================
    // CLOCK 1
    // 14 ns PERIOD
    // =========================================================

    initial begin

        clk1 = 1'b0;

        forever #7 clk1 = ~clk1;

    end


    // =========================================================
    // VCD
    // =========================================================

    initial begin

        $dumpfile("glitch_free_clock_mux_tb.vcd");

        $dumpvars(0, glitch_free_clock_mux_tb);

    end


    // =========================================================
    // COUNT OUTPUT RISING EDGES
    // =========================================================

    always @(posedge clk_out) begin

        rising_edges = rising_edges + 1;

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | RESET=%b | SELECT=%b | CLK0=%b | CLK1=%b | EN0=%b | EN1=%b | CLK_OUT=%b",
            $time,
            rst,
            select,
            clk0,
            clk1,
            dut.en0,
            dut.en1,
            clk_out
        );

    end


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        errors = 0;
        rising_edges = 0;

        rst = 1'b1;
        select = 1'b0;


        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        #20;

        rst = 1'b0;


        // =====================================================
        // TEST 1: SELECT CLOCK 0
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 1: CLOCK 0 SELECTED");
        $display("========================================");

        select = 1'b0;

        #50;

        if (dut.en0 !== 1'b1) begin

            $display("FAIL: TEST 1 | EN0 SHOULD BE 1");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 1 | CLOCK 0 ENABLED");

        end


        if (dut.en1 !== 1'b0) begin

            $display("FAIL: TEST 1 | EN1 SHOULD BE 0");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 1 | CLOCK 1 DISABLED");

        end


        // =====================================================
        // TEST 2: SWITCH TO CLOCK 1
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: SWITCH TO CLOCK 1");
        $display("========================================");

        select = 1'b1;

        // Give enough time for clock switching
        #60;

        if (dut.en1 !== 1'b1) begin

            $display("FAIL: TEST 2 | EN1 SHOULD BE 1");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | CLOCK 1 ENABLED");

        end


        if (dut.en0 !== 1'b0) begin

            $display("FAIL: TEST 2 | EN0 SHOULD BE 0");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | CLOCK 0 DISABLED");

        end


        // =====================================================
        // TEST 3: SWITCH BACK TO CLOCK 0
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: SWITCH BACK TO CLOCK 0");
        $display("========================================");

        select = 1'b0;

        #60;

        if (dut.en0 !== 1'b1) begin

            $display("FAIL: TEST 3 | EN0 SHOULD BE 1");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 3 | CLOCK 0 ENABLED AGAIN");

        end


        if (dut.en1 !== 1'b0) begin

            $display("FAIL: TEST 3 | EN1 SHOULD BE 0");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 3 | CLOCK 1 DISABLED");

        end


        // =====================================================
        // TEST 4: BOTH CLOCKS NEVER ENABLED TOGETHER
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 4: MUTUAL EXCLUSION");
        $display("========================================");

        if ((dut.en0 === 1'b1) &&
            (dut.en1 === 1'b1)) begin

            $display("FAIL: TEST 4 | BOTH CLOCKS ENABLED");

            errors = errors + 1;

        end

        else begin

            $display(
                "PASS: TEST 4 | CLOCK ENABLES ARE MUTUALLY EXCLUSIVE"
            );

        end


        // =====================================================
        // FINISH
        // =====================================================

        #20;

        $display("");
        $display("========================================");

        if (errors == 0) begin

            $display("ALL GLITCH-FREE CLOCK MUX TESTS PASSED");

        end

        else begin

            $display("GLITCH-FREE CLOCK MUX TEST FAILED");

            $display("ERRORS = %0d", errors);

        end

        $display("========================================");

        $finish;

    end

endmodule