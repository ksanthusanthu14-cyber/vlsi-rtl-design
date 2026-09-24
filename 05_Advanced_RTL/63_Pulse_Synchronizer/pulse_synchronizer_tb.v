`timescale 1ns/1ps

module pulse_synchronizer_tb;

    reg src_clk;
    reg dest_clk;
    reg rst;

    reg pulse_in;

    wire pulse_out;

    integer errors;
    integer pulse_count;


    // =========================================================
    // DUT
    // =========================================================

    pulse_synchronizer dut (

        .src_clk(src_clk),
        .dest_clk(dest_clk),
        .rst(rst),

        .pulse_in(pulse_in),

        .pulse_out(pulse_out)

    );


    // =========================================================
    // SOURCE CLOCK
    // 10 ns period
    // =========================================================

    initial begin

        src_clk = 1'b0;

        forever #5 src_clk = ~src_clk;

    end


    // =========================================================
    // DESTINATION CLOCK
    // 14 ns period
    // =========================================================

    initial begin

        dest_clk = 1'b0;

        forever #7 dest_clk = ~dest_clk;

    end


    // =========================================================
    // VCD
    // =========================================================

    initial begin

        $dumpfile("pulse_synchronizer_tb.vcd");

        $dumpvars(0, pulse_synchronizer_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | RESET=%b | SRC_PULSE=%b | SRC_TOGGLE=%b | FF1=%b | FF2=%b | FF2_PREV=%b | DEST_PULSE=%b",
            $time,
            rst,
            pulse_in,
            dut.src_toggle,
            dut.sync_ff1,
            dut.sync_ff2,
            dut.sync_ff2_prev,
            pulse_out
        );

    end


    // =========================================================
    // COUNT DESTINATION PULSES
    // Sample on falling edge so pulse_out has already updated.
    // =========================================================

    always @(negedge dest_clk) begin

        if (pulse_out)
            pulse_count = pulse_count + 1;

    end


    // =========================================================
    // TEST SEQUENCE
    // =========================================================

    initial begin

        errors = 0;
        pulse_count = 0;

        // -----------------------------------------------------
        // INITIAL CONDITIONS
        // -----------------------------------------------------

        rst = 1'b1;
        pulse_in = 1'b0;


        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        #20;

        rst = 1'b0;


        // =====================================================
        // TEST 1: SINGLE SHORT PULSE
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 1: SINGLE SHORT PULSE");
        $display("========================================");

        // Pulse overlaps source clock at 25 ns.
        #3;

        pulse_in = 1'b1;

        #3;

        pulse_in = 1'b0;


        // Wait for destination synchronization

        #60;

        if (pulse_count != 1) begin

            $display(
                "FAIL: TEST 1 | EXPECTED=1 | RECEIVED=%0d",
                pulse_count
            );

            errors = errors + 1;

        end

        else begin

            $display(
                "PASS: TEST 1 | SINGLE PULSE TRANSFERRED"
            );

        end


        // =====================================================
        // TEST 2: SECOND PULSE
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: SECOND PULSE");
        $display("========================================");

        // Current time is around 86 ns.
        // Generate pulse around source rising edge at 95 ns.

        #6;

        pulse_in = 1'b1;

        #4;

        pulse_in = 1'b0;


        #60;

        if (pulse_count != 2) begin

            $display(
                "FAIL: TEST 2 | EXPECTED=2 | RECEIVED=%0d",
                pulse_count
            );

            errors = errors + 1;

        end

        else begin

            $display(
                "PASS: TEST 2 | SECOND PULSE TRANSFERRED"
            );

        end


        // =====================================================
        // TEST 3: THIRD PULSE
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: THIRD PULSE");
        $display("========================================");

        // Generate another pulse overlapping a source clock.

        #6;

        pulse_in = 1'b1;

        #4;

        pulse_in = 1'b0;


        #60;

        if (pulse_count != 3) begin

            $display(
                "FAIL: TEST 3 | EXPECTED=3 | RECEIVED=%0d",
                pulse_count
            );

            errors = errors + 1;

        end

        else begin

            $display(
                "PASS: TEST 3 | THIRD PULSE TRANSFERRED"
            );

        end


        // =====================================================
        // TEST 4: NO INPUT PULSE
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 4: NO FALSE PULSE");
        $display("========================================");

        #40;

        if (pulse_count != 3) begin

            $display(
                "FAIL: TEST 4 | UNEXPECTED DESTINATION PULSE"
            );

            errors = errors + 1;

        end

        else begin

            $display(
                "PASS: TEST 4 | NO FALSE PULSE"
            );

        end


        // =====================================================
        // FINAL RESULT
        // =====================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin

            $display("ALL PULSE SYNCHRONIZER TESTS PASSED");

        end

        else begin

            $display("PULSE SYNCHRONIZER TEST FAILED");
            $display("ERRORS = %0d", errors);

        end

        $display("========================================");

        $finish;

    end

endmodule