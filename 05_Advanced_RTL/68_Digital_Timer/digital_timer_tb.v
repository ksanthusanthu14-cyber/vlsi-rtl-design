`timescale 1ns/1ps

module digital_timer_tb;

    reg clk;
    reg rst;

    reg load;
    reg start;
    reg pause;
    reg clear;

    reg [4:0] load_hours;
    reg [5:0] load_minutes;
    reg [5:0] load_seconds;

    wire [4:0] hours;
    wire [5:0] minutes;
    wire [5:0] seconds;

    wire running;
    wire done;

    integer errors;


    // =========================================================
    // DUT
    // =========================================================

    digital_timer #(
        .CLK_DIV(4)
    ) dut (

        .clk(clk),
        .rst(rst),

        .load(load),
        .start(start),
        .pause(pause),
        .clear(clear),

        .load_hours(load_hours),
        .load_minutes(load_minutes),
        .load_seconds(load_seconds),

        .hours(hours),
        .minutes(minutes),
        .seconds(seconds),

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
    // VCD
    // =========================================================

    initial begin

        $dumpfile("digital_timer_tb.vcd");

        $dumpvars(0, digital_timer_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | RESET=%b | LOAD=%b | START=%b | PAUSE=%b | CLEAR=%b | RUN=%b | DONE=%b | DIV=%0d | TIME=%02d:%02d:%02d",
            $time,
            rst,
            load,
            start,
            pause,
            clear,
            running,
            done,
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

        load  = 1'b0;
        start = 1'b0;
        pause = 1'b0;
        clear = 1'b0;

        load_hours   = 0;
        load_minutes = 0;
        load_seconds = 0;


        // =====================================================
        // TEST 1: RESET
        // =====================================================

        #20;

        rst = 1'b0;

        #1;

        if ((hours != 0) ||
            (minutes != 0) ||
            (seconds != 0) ||
            (running != 0) ||
            (done != 0)) begin

            $display("FAIL: TEST 1 | RESET STATE INVALID");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 1 | RESET = 00:00:00");

        end


        // =====================================================
        // TEST 2: LOAD 00:00:05
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: LOAD TIMER");
        $display("========================================");

        load_hours   = 0;
        load_minutes = 0;
        load_seconds = 5;

        load = 1'b1;

        @(posedge clk);
        #1;

        load = 1'b0;

        if ((hours != 0) ||
            (minutes != 0) ||
            (seconds != 5) ||
            (running != 0)) begin

            $display(
                "FAIL: TEST 2 | EXPECTED 00:00:05 | GOT %02d:%02d:%02d",
                hours,
                minutes,
                seconds
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | LOADED 00:00:05");

        end


        // =====================================================
        // TEST 3: START
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: START TIMER");
        $display("========================================");

        start = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;

        if (running != 1'b1) begin

            $display("FAIL: TEST 3 | TIMER DID NOT START");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 3 | TIMER RUNNING");

        end


        // =====================================================
        // TEST 4: COUNTDOWN
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 4: COUNTDOWN");
        $display("========================================");

        // Four clock cycles = one simulated second
        repeat (4) @(posedge clk);

        #1;

        if (seconds != 4) begin

            $display(
                "FAIL: TEST 4 | EXPECTED 00:00:04 | GOT %02d:%02d:%02d",
                hours,
                minutes,
                seconds
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 4 | 00:00:05 -> 00:00:04");

        end


        // =====================================================
        // TEST 5: PAUSE
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 5: PAUSE");
        $display("========================================");

        pause = 1'b1;

        @(posedge clk);
        #1;

        pause = 1'b0;

        if (running != 1'b0) begin

            $display("FAIL: TEST 5 | TIMER DID NOT PAUSE");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 5 | TIMER PAUSED");

        end


        repeat (8) @(posedge clk);

        #1;

        if (seconds != 4) begin

            $display("FAIL: TEST 5 | TIME CHANGED WHILE PAUSED");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 5 | TIME HELD AT 00:00:04");

        end


        // =====================================================
        // TEST 6: RESUME
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 6: RESUME");
        $display("========================================");

        start = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;

        if (running != 1'b1) begin

            $display("FAIL: TEST 6 | TIMER DID NOT RESUME");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 6 | TIMER RESUMED");

        end


        // =====================================================
        // TEST 7: COMPLETE COUNTDOWN
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 7: TIMER COMPLETION");
        $display("========================================");

        // 4 seconds remaining.
        // Wait enough cycles to reach zero.
        repeat (16) @(posedge clk);

        #1;

        if ((hours != 0) ||
            (minutes != 0) ||
            (seconds != 0) ||
            (running != 0)) begin

            $display(
                "FAIL: TEST 7 | EXPECTED STOPPED 00:00:00"
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 7 | TIMER REACHED ZERO");

        end


        // =====================================================
        // TEST 8: LOAD 00:01:00
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 8: MINUTE BORROW");
        $display("========================================");

        load_hours   = 0;
        load_minutes = 1;
        load_seconds = 0;

        load = 1'b1;

        @(posedge clk);
        #1;

        load = 1'b0;

        start = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;

        // Force to 00:01:00 with next tick
        dut.div_count = 3;

        @(posedge clk);
        #1;

        if ((hours != 0) ||
            (minutes != 0) ||
            (seconds != 59)) begin

            $display(
                "FAIL: TEST 8 | EXPECTED 00:00:59 | GOT %02d:%02d:%02d",
                hours,
                minutes,
                seconds
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 8 | 00:01:00 -> 00:00:59");

        end


        // =====================================================
        // TEST 9: CLEAR
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 9: CLEAR");
        $display("========================================");

        clear = 1'b1;

        @(posedge clk);
        #1;

        clear = 1'b0;

        if ((hours != 0) ||
            (minutes != 0) ||
            (seconds != 0) ||
            (running != 0) ||
            (done != 0)) begin

            $display("FAIL: TEST 9 | CLEAR FAILED");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 9 | TIMER CLEARED");

        end


        // =====================================================
        // FINAL RESULT
        // =====================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin

            $display("ALL DIGITAL TIMER TESTS PASSED");

        end

        else begin

            $display("DIGITAL TIMER TEST FAILED");

            $display("ERRORS = %0d", errors);

        end

        $display("========================================");

        $finish;

    end

endmodule