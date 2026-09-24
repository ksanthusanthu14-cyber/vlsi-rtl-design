`timescale 1ns/1ps

module digital_clock_tb;

    reg clk;
    reg rst;
    reg enable;

    wire [5:0] seconds;
    wire [5:0] minutes;
    wire [4:0] hours;

    integer errors;


    // =========================================================
    // DUT
    // =========================================================

    digital_clock #(
        .CLK_DIV(4)
    ) dut (

        .clk(clk),
        .rst(rst),
        .enable(enable),

        .seconds(seconds),
        .minutes(minutes),
        .hours(hours)

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

        $dumpfile("digital_clock_tb.vcd");

        $dumpvars(0, digital_clock_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | RESET=%b | ENABLE=%b | DIV=%0d | TIME=%02d:%02d:%02d",
            $time,
            rst,
            enable,
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
        enable = 1'b0;


        // =====================================================
        // RESET TEST
        // =====================================================

        #20;

        rst = 1'b0;
        enable = 1'b1;

        #5;

        if ((hours != 0) ||
            (minutes != 0) ||
            (seconds != 0)) begin

            $display("FAIL: RESET | CLOCK NOT ZERO");

            errors = errors + 1;

        end

        else begin

            $display("PASS: RESET | CLOCK = 00:00:00");

        end


        // =====================================================
        // TEST 1: SECONDS
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 1: SECOND COUNTING");
        $display("========================================");

        // CLK_DIV = 4
        // One second occurs every 4 clock cycles.

        repeat (4) @(posedge clk);

        #1;

        if (seconds != 1) begin

            $display(
                "FAIL: TEST 1 | EXPECTED 00:00:01 | GOT %02d:%02d:%02d",
                hours,
                minutes,
                seconds
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 1 | SECOND INCREMENTED");

        end


        // =====================================================
        // TEST 2: MINUTE ROLLOVER
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: MINUTE ROLLOVER");
        $display("========================================");

        // Force time to 00:00:59
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
                "FAIL: TEST 2 | EXPECTED 00:01:00 | GOT %02d:%02d:%02d",
                hours,
                minutes,
                seconds
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | 00:00:59 -> 00:01:00");

        end


        // =====================================================
        // TEST 3: HOUR ROLLOVER
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: HOUR ROLLOVER");
        $display("========================================");

        // Force time to 00:59:59
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
                "FAIL: TEST 3 | EXPECTED 01:00:00 | GOT %02d:%02d:%02d",
                hours,
                minutes,
                seconds
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 3 | 00:59:59 -> 01:00:00");

        end


        // =====================================================
        // TEST 4: 23:59:59 -> 00:00:00
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 4: DAY ROLLOVER");
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
                "FAIL: TEST 4 | EXPECTED 00:00:00 | GOT %02d:%02d:%02d",
                hours,
                minutes,
                seconds
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 4 | 23:59:59 -> 00:00:00");

        end


        // =====================================================
        // TEST 5: DISABLE
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 5: CLOCK DISABLE");
        $display("========================================");

        dut.hours = 5;
        dut.minutes = 20;
        dut.seconds = 30;

        enable = 1'b0;

        repeat (5) @(posedge clk);

        #1;

        if ((hours != 5) ||
            (minutes != 20) ||
            (seconds != 30)) begin

            $display(
                "FAIL: TEST 5 | CLOCK CHANGED WHILE DISABLED"
            );

            errors = errors + 1;

        end

        else begin

            $display(
                "PASS: TEST 5 | CLOCK HELD AT 05:20:30"
            );

        end


        // =====================================================
        // FINAL RESULT
        // =====================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin

            $display("ALL DIGITAL CLOCK TESTS PASSED");

        end

        else begin

            $display("DIGITAL CLOCK TEST FAILED");

            $display("ERRORS = %0d", errors);

        end

        $display("========================================");

        $finish;

    end

endmodule