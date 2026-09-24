`timescale 1ns/1ps

module stopwatch_tb;

    reg clk;
    reg rst;
    reg start_stop;

    wire [5:0] seconds;
    wire [5:0] minutes;
    wire [4:0] hours;
    wire running;

    integer errors;


    // =========================================================
    // DUT
    // =========================================================

    stopwatch #(
        .CLK_DIV(4)
    ) dut (

        .clk(clk),
        .rst(rst),
        .start_stop(start_stop),

        .seconds(seconds),
        .minutes(minutes),
        .hours(hours),
        .running(running)

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

        $dumpfile("stopwatch_tb.vcd");

        $dumpvars(0, stopwatch_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | RESET=%b | START_STOP=%b | RUNNING=%b | DIV=%0d | TIME=%02d:%02d:%02d",
            $time,
            rst,
            start_stop,
            running,
            dut.div_count,
            hours,
            minutes,
            seconds
        );

    end


    // =========================================================
    // TEST SEQUENCE
    // =========================================================

    initial begin

        errors = 0;

        rst = 1'b1;
        start_stop = 1'b0;


        // =====================================================
        // RESET
        // =====================================================

        #20;

        rst = 1'b0;

        #1;

        if ((hours != 0) ||
            (minutes != 0) ||
            (seconds != 0) ||
            (running != 0)) begin

            $display("FAIL: RESET | INVALID INITIAL STATE");

            errors = errors + 1;

        end

        else begin

            $display("PASS: RESET | STOPWATCH = 00:00:00 | STOPPED");

        end


        // =====================================================
        // TEST 1: START
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 1: START STOPWATCH");
        $display("========================================");

        start_stop = 1'b1;

        @(posedge clk);
        #1;

        start_stop = 1'b0;

        if (running != 1'b1) begin

            $display("FAIL: TEST 1 | STOPWATCH DID NOT START");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 1 | STOPWATCH RUNNING");

        end


        // =====================================================
        // TEST 2: COUNT
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: COUNTING");
        $display("========================================");

        repeat (4) @(posedge clk);

        #1;

        if (seconds != 1) begin

            $display(
                "FAIL: TEST 2 | EXPECTED 00:00:01 | GOT %02d:%02d:%02d",
                hours,
                minutes,
                seconds
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | ONE SECOND COUNTED");

        end


        // =====================================================
        // TEST 3: STOP / PAUSE
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: STOP / PAUSE");
        $display("========================================");

        start_stop = 1'b1;

        @(posedge clk);
        #1;

        start_stop = 1'b0;

        #1;

        if (running != 1'b0) begin

            $display("FAIL: TEST 3 | STOPWATCH DID NOT STOP");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 3 | STOPWATCH STOPPED");

        end


        // Save current time
        #1;

        // Wait while stopped
        repeat (8) @(posedge clk);

        #1;

        if ((hours != 0) ||
            (minutes != 0) ||
            (seconds != 1)) begin

            $display(
                "FAIL: TEST 3 | TIME CHANGED WHILE STOPPED"
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 3 | TIME HELD WHILE STOPPED");

        end


        // =====================================================
        // TEST 4: RESTART
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 4: RESTART");
        $display("========================================");

        start_stop = 1'b1;

        @(posedge clk);
        #1;

        start_stop = 1'b0;

        if (running != 1'b1) begin

            $display("FAIL: TEST 4 | STOPWATCH DID NOT RESTART");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 4 | STOPWATCH RESTARTED");

        end


        // =====================================================
        // TEST 5: MINUTE ROLLOVER
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 5: MINUTE ROLLOVER");
        $display("========================================");

        dut.hours = 0;
        dut.minutes = 0;
        dut.seconds = 59;
        dut.div_count = 3;

        @(posedge clk);
        #1;

        if ((hours != 0) ||
            (minutes != 1) ||
            (seconds != 0)) begin

            $display(
                "FAIL: TEST 5 | EXPECTED 00:01:00 | GOT %02d:%02d:%02d",
                hours,
                minutes,
                seconds
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 5 | 00:00:59 -> 00:01:00");

        end


        // =====================================================
        // TEST 6: HOUR ROLLOVER
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 6: HOUR ROLLOVER");
        $display("========================================");

        dut.hours = 0;
        dut.minutes = 59;
        dut.seconds = 59;
        dut.div_count = 3;

        @(posedge clk);
        #1;

        if ((hours != 1) ||
            (minutes != 0) ||
            (seconds != 0)) begin

            $display(
                "FAIL: TEST 6 | EXPECTED 01:00:00 | GOT %02d:%02d:%02d",
                hours,
                minutes,
                seconds
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 6 | 00:59:59 -> 01:00:00");

        end


        // =====================================================
        // TEST 7: 23:59:59 ROLLOVER
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 7: DAY ROLLOVER");
        $display("========================================");

        dut.hours = 23;
        dut.minutes = 59;
        dut.seconds = 59;
        dut.div_count = 3;

        @(posedge clk);
        #1;

        if ((hours != 0) ||
            (minutes != 0) ||
            (seconds != 0)) begin

            $display(
                "FAIL: TEST 7 | EXPECTED 00:00:00 | GOT %02d:%02d:%02d",
                hours,
                minutes,
                seconds
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 7 | 23:59:59 -> 00:00:00");

        end


        // =====================================================
        // TEST 8: RESET WHILE RUNNING
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 8: RESET WHILE RUNNING");
        $display("========================================");

        rst = 1'b1;

        #1;

        if ((hours != 0) ||
            (minutes != 0) ||
            (seconds != 0) ||
            (running != 0)) begin

            $display("FAIL: TEST 8 | RESET FAILED");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 8 | RESET CLEARED STOPWATCH");

        end

        rst = 1'b0;


        // =====================================================
        // FINAL RESULT
        // =====================================================

        #10;

        $display("");
        $display("========================================");

        if (errors == 0) begin

            $display("ALL STOPWATCH TESTS PASSED");

        end

        else begin

            $display("STOPWATCH TEST FAILED");

            $display("ERRORS = %0d", errors);

        end

        $display("========================================");

        $finish;

    end

endmodule