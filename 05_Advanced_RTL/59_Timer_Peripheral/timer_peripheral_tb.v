`timescale 1ns/1ps

module timer_peripheral_tb;

    // =========================================================
    // TESTBENCH SIGNALS
    // =========================================================

    reg clk;
    reg rst;

    reg enable;
    reg start;
    reg clear;

    reg [7:0] period_value;

    wire [7:0] counter;
    wire running;
    wire done;

    integer errors;


    // =========================================================
    // DUT
    // =========================================================

    timer_peripheral #(
        .WIDTH(8)
    ) dut (

        .clk(clk),
        .rst(rst),

        .enable(enable),
        .start(start),
        .clear(clear),

        .period_value(period_value),

        .counter(counter),
        .running(running),
        .done(done)

    );


    // =========================================================
    // CLOCK
    // =========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // =========================================================
    // WAVEFORM
    // =========================================================

    initial begin

        $dumpfile("timer_peripheral_tb.vcd");

        $dumpvars(0, timer_peripheral_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | RESET=%b | ENABLE=%b | START=%b | CLEAR=%b | PERIOD=%0d | COUNTER=%0d | RUNNING=%b | DONE=%b",
            $time,
            rst,
            enable,
            start,
            clear,
            period_value,
            counter,
            running,
            done
        );

    end


    // =========================================================
    // MAIN TEST
    // =========================================================

    initial begin

        errors = 0;

        // -----------------------------------------------------
        // INITIAL CONDITIONS
        // -----------------------------------------------------

        rst = 1'b1;

        enable = 1'b0;
        start = 1'b0;
        clear = 1'b0;

        period_value = 8'd5;


        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        #20;

        rst = 1'b0;

        enable = 1'b1;


        // =====================================================
        // TEST 1: COMPLETE COUNTDOWN
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 1: COMPLETE COUNTDOWN");
        $display("========================================");

        period_value = 8'd5;

        start = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;

        // Counter: 5 -> 4 -> 3 -> 2 -> 1

        repeat (4) begin
            @(posedge clk);
            #1;
        end

        // Counter should now reach zero and DONE should assert

        @(posedge clk);
        #1;

        if (counter !== 8'd0 ||
            running !== 1'b0 ||
            done !== 1'b1) begin

            $display("FAIL: TEST 1");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 1 | COUNTDOWN COMPLETED");

        end


        // =====================================================
        // TEST 2: RESTART WITH DIFFERENT PERIOD
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: RESTART TIMER");
        $display("========================================");

        period_value = 8'd8;

        start = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;

        if (counter !== 8'd8 ||
            running !== 1'b1 ||
            done !== 1'b0) begin

            $display("FAIL: TEST 2 | TIMER DID NOT RESTART");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | TIMER RESTARTED WITH PERIOD 8");

        end


        // Allow complete countdown

        repeat (7) begin
            @(posedge clk);
            #1;
        end

        @(posedge clk);
        #1;


        if (counter !== 8'd0 ||
            running !== 1'b0 ||
            done !== 1'b1) begin

            $display("FAIL: TEST 2 | COUNTDOWN");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | COUNTDOWN COMPLETED");

        end


        // =====================================================
        // TEST 3: CLEAR TIMER
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: CLEAR TIMER");
        $display("========================================");

        period_value = 8'd10;

        start = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;

        // Let timer run for two cycles

        repeat (2) begin
            @(posedge clk);
            #1;
        end

        clear = 1'b1;

        @(posedge clk);
        #1;

        clear = 1'b0;

        if (counter !== 8'd0 ||
            running !== 1'b0 ||
            done !== 1'b0) begin

            $display("FAIL: TEST 3 | CLEAR");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 3 | TIMER CLEARED");

        end


        // =====================================================
        // TEST 4: DISABLE TIMER
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 4: DISABLE TIMER");
        $display("========================================");

        period_value = 8'd6;

        start = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;

        // Let timer start running

        @(posedge clk);
        #1;

        enable = 1'b0;

        @(posedge clk);
        #1;

        if (counter !== 8'd0 ||
            running !== 1'b0 ||
            done !== 1'b0) begin

            $display("FAIL: TEST 4 | DISABLE");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 4 | TIMER DISABLED");

        end


        // =====================================================
        // FINAL RESULT
        // =====================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin

            $display("ALL TIMER PERIPHERAL TESTS PASSED");

        end

        else begin

            $display("TIMER PERIPHERAL TEST FAILED");
            $display("ERRORS = %0d", errors);

        end

        $display("========================================");

        $finish;

    end

endmodule