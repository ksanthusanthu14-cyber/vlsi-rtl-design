`timescale 1ns/1ps

module timing_closure_tb;

    parameter integer TCLK   = 10;
    parameter integer TCQ    = 1;
    parameter integer TSETUP = 1;

    integer allowed_delay;

    integer path_delay;
    integer slack;

    integer fmax_mhz;

    integer passed;
    integer failed;

    task automatic analyze_stage;
        input integer stage;
        input integer delay;

        integer stage_slack;
        integer stage_period;
        integer stage_fmax;

        begin

            stage_slack = allowed_delay - delay;

            stage_period = TCQ + delay + TSETUP;

            stage_fmax = 1000 / stage_period;

            $display("");
            $display("================================================");
            $display("TIMING CLOSURE STAGE %0d", stage);
            $display("================================================");

            $display(
                "Critical Path Delay = %0d ns",
                delay
            );

            $display(
                "Allowed Path Delay = %0d ns",
                allowed_delay
            );

            $display(
                "Setup Slack = %0d ns",
                stage_slack
            );

            $display(
                "Minimum Clock Period = %0d ns",
                stage_period
            );

            $display(
                "Maximum Frequency = %0d MHz",
                stage_fmax
            );

            if (stage_slack < 0) begin

                $display(
                    "STATUS = TIMING VIOLATION"
                );

            end
            else if (stage_slack == 0) begin

                $display(
                    "STATUS = ZERO-SLACK BOUNDARY"
                );

            end
            else begin

                $display(
                    "STATUS = TIMING CLOSED"
                );

            end

        end
    endtask


    initial begin

        passed = 0;
        failed = 0;

        // ------------------------------------------------
        // Timing parameters
        // ------------------------------------------------

        allowed_delay =
            TCLK - TCQ - TSETUP;

        $display("");
        $display("================================================");
        $display("           TIMING CLOSURE EXERCISE");
        $display("================================================");

        $display("");
        $display(
            "Clock Period = %0d ns",
            TCLK
        );

        $display(
            "Clock-to-Q = %0d ns",
            TCQ
        );

        $display(
            "Setup Time = %0d ns",
            TSETUP
        );

        $display("");
        $display(
            "Maximum Allowed Path Delay = %0d ns",
            allowed_delay
        );

        $display("");
        $display("Timing Closure Strategy:");
        $display("Reduce the critical-path delay");

        // ------------------------------------------------
        // Stage 1
        // ------------------------------------------------

        analyze_stage(1, 11);

        // ------------------------------------------------
        // Stage 2
        // ------------------------------------------------

        analyze_stage(2, 9);

        // ------------------------------------------------
        // Stage 3
        // ------------------------------------------------

        analyze_stage(3, 8);

        // ------------------------------------------------
        // Stage 4
        // ------------------------------------------------

        analyze_stage(4, 7);

        // ------------------------------------------------
        // Stage 5
        // ------------------------------------------------

        analyze_stage(5, 6);

        // ------------------------------------------------
        // Verification
        // ------------------------------------------------

        $display("");
        $display("================================================");
        $display("             CLOSURE VERIFICATION");
        $display("================================================");

        // Stage 1 must violate timing
        if ((allowed_delay - 11) < 0) begin
            $display(
                "CHECK 1: INITIAL VIOLATION DETECTED"
            );
            passed = passed + 1;
        end
        else begin
            $display(
                "CHECK 1: FAILED"
            );
            failed = failed + 1;
        end

        // Stage 2 must still violate timing
        if ((allowed_delay - 9) < 0) begin
            $display(
                "CHECK 2: INTERMEDIATE VIOLATION DETECTED"
            );
            passed = passed + 1;
        end
        else begin
            $display(
                "CHECK 2: FAILED"
            );
            failed = failed + 1;
        end

        // Stage 3 must be zero slack
        if ((allowed_delay - 8) == 0) begin
            $display(
                "CHECK 3: ZERO-SLACK BOUNDARY DETECTED"
            );
            passed = passed + 1;
        end
        else begin
            $display(
                "CHECK 3: FAILED"
            );
            failed = failed + 1;
        end

        // Stage 4 must close timing
        if ((allowed_delay - 7) > 0) begin
            $display(
                "CHECK 4: TIMING CLOSURE ACHIEVED"
            );
            passed = passed + 1;
        end
        else begin
            $display(
                "CHECK 4: FAILED"
            );
            failed = failed + 1;
        end

        // Stage 5 must have better slack
        if ((allowed_delay - 6) > 0) begin
            $display(
                "CHECK 5: ADDITIONAL TIMING MARGIN ACHIEVED"
            );
            passed = passed + 1;
        end
        else begin
            $display(
                "CHECK 5: FAILED"
            );
            failed = failed + 1;
        end

        // ------------------------------------------------
        // Final result
        // ------------------------------------------------

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display(
            "INITIAL SLACK = %0d ns",
            allowed_delay - 11
        );

        $display(
            "FINAL SLACK = %0d ns",
            allowed_delay - 6
        );

        $display(
            "TOTAL CHECKS = 5"
        );

        $display(
            "PASSED CHECKS = %0d",
            passed
        );

        $display(
            "FAILED CHECKS = %0d",
            failed
        );

        $display("");

        if (failed == 0)
            $display(
                "OVERALL RESULT = PASS"
            );
        else
            $display(
                "OVERALL RESULT = FAIL"
            );

        $display("================================================");

        $finish;

    end

endmodule