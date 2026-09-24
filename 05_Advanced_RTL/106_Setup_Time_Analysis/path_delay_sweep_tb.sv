`timescale 1ns/1ps

module path_delay_sweep_tb;

    // =========================================================
    // FIXED TIMING PARAMETERS
    // =========================================================

    parameter integer TCLK   = 10;
    parameter integer TCQ    = 1;
    parameter integer TSETUP = 1;

    integer max_comb_delay;

    integer comb_delay;
    integer slack;

    integer passed;
    integer failed;


    // =========================================================
    // ANALYZE ONE COMBINATIONAL DELAY
    // =========================================================

    task automatic analyze_delay;

        input integer delay;

        begin

            slack = TCLK - TCQ - delay - TSETUP;

            $display(
                "Tcomb = %0d ns | Slack = %0d ns",
                delay,
                slack
            );

            // -------------------------------------------------
            // Verify timing classification
            // -------------------------------------------------

            if (delay < max_comb_delay) begin

                if (slack > 0) begin

                    $display(
                        "             STATUS = TIMING MET"
                    );

                    passed = passed + 1;

                end
                else begin

                    $display(
                        "             ERROR: EXPECTED POSITIVE SLACK"
                    );

                    failed = failed + 1;

                end

            end

            else if (delay == max_comb_delay) begin

                if (slack == 0) begin

                    $display(
                        "             STATUS = ZERO-SLACK BOUNDARY"
                    );

                    passed = passed + 1;

                end
                else begin

                    $display(
                        "             ERROR: EXPECTED ZERO SLACK"
                    );

                    failed = failed + 1;

                end

            end

            else begin

                if (slack < 0) begin

                    $display(
                        "             STATUS = SETUP VIOLATION"
                    );

                    passed = passed + 1;

                end
                else begin

                    $display(
                        "             ERROR: EXPECTED NEGATIVE SLACK"
                    );

                    failed = failed + 1;

                end

            end

        end

    endtask


    // =========================================================
    // MAIN
    // =========================================================

    initial begin

        passed = 0;
        failed = 0;

        // -----------------------------------------------------
        // Calculate maximum combinational delay
        // -----------------------------------------------------

        max_comb_delay = TCLK - TCQ - TSETUP;


        $display("");
        $display("================================================");
        $display("       COMBINATIONAL DELAY ANALYSIS");
        $display("================================================");

        $display("");

        $display("Clock Period       = %0d ns", TCLK);
        $display("Clock-to-Q         = %0d ns", TCQ);
        $display("Setup Time         = %0d ns", TSETUP);

        $display("");

        $display(
            "Maximum Combinational Delay = Tclk - Tcq - Tsetup"
        );

        $display(
            "Maximum Combinational Delay = %0d - %0d - %0d",
            TCLK,
            TCQ,
            TSETUP
        );

        $display(
            "Maximum Combinational Delay = %0d ns",
            max_comb_delay
        );

        $display("");

        $display("-----------------------------------------------");
        $display("DELAY SWEEP");
        $display("-----------------------------------------------");


        // =====================================================
        // SAFE DELAYS
        // =====================================================

        analyze_delay(2);
        analyze_delay(4);
        analyze_delay(6);
        analyze_delay(7);


        // =====================================================
        // BOUNDARY
        // =====================================================

        analyze_delay(8);


        // =====================================================
        // VIOLATING DELAYS
        // =====================================================

        analyze_delay(9);
        analyze_delay(10);


        // =====================================================
        // FINAL REPORT
        // =====================================================

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display(
            "MAX COMBINATIONAL DELAY = %0d ns",
            max_comb_delay
        );

        $display(
            "TOTAL CHECKS           = 7"
        );

        $display(
            "PASSED CHECKS          = %0d",
            passed
        );

        $display(
            "FAILED CHECKS          = %0d",
            failed
        );

        $display("");

        if (failed == 0) begin

            $display(
                "OVERALL RESULT = PASS"
            );

        end
        else begin

            $display(
                "OVERALL RESULT = FAIL"
            );

        end

        $display("================================================");

        $finish;

    end

endmodule