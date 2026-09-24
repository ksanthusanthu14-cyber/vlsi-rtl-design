`timescale 1ns/1ps

module edge_detector_tb;

    // =========================================================
    // TESTBENCH SIGNALS
    // =========================================================

    reg clk;
    reg rst;
    reg enable;

    reg signal_in;

    wire rising_edge;
    wire falling_edge;

    integer errors;


    // =========================================================
    // DUT
    // =========================================================

    edge_detector dut (

        .clk(clk),
        .rst(rst),
        .enable(enable),

        .signal_in(signal_in),

        .rising_edge(rising_edge),
        .falling_edge(falling_edge)

    );


    // =========================================================
    // CLOCK
    // =========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // =========================================================
    // VCD
    // =========================================================

    initial begin

        $dumpfile("edge_detector_tb.vcd");

        $dumpvars(0, edge_detector_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | RESET=%b | ENABLE=%b | SIGNAL=%b | PREV=%b | RISING=%b | FALLING=%b",
            $time,
            rst,
            enable,
            signal_in,
            dut.signal_prev,
            rising_edge,
            falling_edge
        );

    end


    // =========================================================
    // TEST SEQUENCE
    // =========================================================

    initial begin

        errors = 0;

        // -----------------------------------------------------
        // INITIAL CONDITIONS
        // -----------------------------------------------------

        rst = 1'b1;

        enable = 1'b0;

        signal_in = 1'b0;


        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        #20;

        rst = 1'b0;

        enable = 1'b1;


        // =====================================================
        // TEST 1: STABLE LOW
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 1: STABLE LOW");
        $display("========================================");

        signal_in = 1'b0;

        repeat (3) begin
            @(posedge clk);
            #1;
        end

        if (rising_edge !== 1'b0 ||
            falling_edge !== 1'b0) begin

            $display("FAIL: TEST 1");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 1 | NO EDGE");

        end


        // =====================================================
        // TEST 2: RISING EDGE
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: RISING EDGE");
        $display("========================================");

        signal_in = 1'b1;

        @(posedge clk);
        #1;

        if (rising_edge !== 1'b1 ||
            falling_edge !== 1'b0) begin

            $display("FAIL: TEST 2 | RISING EDGE NOT DETECTED");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | RISING EDGE DETECTED");

        end


        // -----------------------------------------------------
        // Verify pulse lasts only one clock
        // -----------------------------------------------------

        @(posedge clk);
        #1;

        if (rising_edge !== 1'b0) begin

            $display("FAIL: TEST 2 | RISING PULSE NOT CLEARED");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | RISING PULSE CLEARED");

        end


        // =====================================================
        // TEST 3: STABLE HIGH
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: STABLE HIGH");
        $display("========================================");

        signal_in = 1'b1;

        repeat (3) begin
            @(posedge clk);
            #1;
        end

        if (rising_edge !== 1'b0 ||
            falling_edge !== 1'b0) begin

            $display("FAIL: TEST 3");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 3 | NO FALSE EDGE");

        end


        // =====================================================
        // TEST 4: FALLING EDGE
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 4: FALLING EDGE");
        $display("========================================");

        signal_in = 1'b0;

        @(posedge clk);
        #1;

        if (falling_edge !== 1'b1 ||
            rising_edge !== 1'b0) begin

            $display("FAIL: TEST 4 | FALLING EDGE NOT DETECTED");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 4 | FALLING EDGE DETECTED");

        end


        // -----------------------------------------------------
        // Verify falling pulse lasts one clock
        // -----------------------------------------------------

        @(posedge clk);
        #1;

        if (falling_edge !== 1'b0) begin

            $display("FAIL: TEST 4 | FALLING PULSE NOT CLEARED");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 4 | FALLING PULSE CLEARED");

        end


        // =====================================================
        // TEST 5: MULTIPLE EDGES
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 5: MULTIPLE EDGES");
        $display("========================================");

        // Rising
        signal_in = 1'b1;

        @(posedge clk);
        #1;

        if (rising_edge !== 1'b1) begin

            $display("FAIL: TEST 5 | RISING EDGE");

            errors = errors + 1;

        end

        // Falling
        signal_in = 1'b0;

        @(posedge clk);
        #1;

        if (falling_edge !== 1'b1) begin

            $display("FAIL: TEST 5 | FALLING EDGE");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 5 | MULTIPLE EDGES DETECTED");

        end


        // =====================================================
        // TEST 6: DISABLE
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 6: DISABLE EDGE DETECTOR");
        $display("========================================");

        enable = 1'b0;

        signal_in = 1'b1;

        @(posedge clk);
        #1;

        if (rising_edge !== 1'b0 ||
            falling_edge !== 1'b0) begin

            $display("FAIL: TEST 6 | OUTPUT ACTIVE WHILE DISABLED");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 6 | DISABLED");

        end


        // =====================================================
        // FINAL RESULT
        // =====================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin

            $display("ALL EDGE DETECTOR TESTS PASSED");

        end

        else begin

            $display("EDGE DETECTOR TEST FAILED");

            $display("ERRORS = %0d", errors);

        end

        $display("========================================");

        $finish;

    end

endmodule