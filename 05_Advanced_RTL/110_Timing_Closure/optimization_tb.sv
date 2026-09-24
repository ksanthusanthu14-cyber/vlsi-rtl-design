`timescale 1ns/1ps

module optimization_tb;

    parameter integer TCLK   = 10;
    parameter integer TCQ    = 1;
    parameter integer TSETUP = 1;

    integer allowed_delay;

    integer initial_delay;
    integer optimized_delay;

    integer initial_slack;
    integer final_slack;

    integer initial_period;
    integer final_period;

    real initial_fmax;
    real final_fmax;

    integer passed;
    integer failed;

    initial begin

        passed = 0;
        failed = 0;

        // ------------------------------------------------
        // Timing budget
        // ------------------------------------------------

        allowed_delay =
            TCLK - TCQ - TSETUP;

        // ------------------------------------------------
        // Initial design
        // ------------------------------------------------

        initial_delay = 11;

        initial_slack =
            allowed_delay - initial_delay;

        initial_period =
            TCQ + initial_delay + TSETUP;

        initial_fmax =
            1000.0 / initial_period;

        // ------------------------------------------------
        // Optimized design
        // ------------------------------------------------

        optimized_delay = 6;

        final_slack =
            allowed_delay - optimized_delay;

        final_period =
            TCQ + optimized_delay + TSETUP;

        final_fmax =
            1000.0 / final_period;

        // ------------------------------------------------
        // Header
        // ------------------------------------------------

        $display("");
        $display("================================================");
        $display("        TIMING OPTIMIZATION ANALYSIS");
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

        $display(
            "Allowed Combinational Delay = %0d ns",
            allowed_delay
        );

        // ------------------------------------------------
        // Initial design
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("INITIAL DESIGN");
        $display("-----------------------------------------------");

        $display(
            "Critical Path = %0d ns",
            initial_delay
        );

        $display(
            "Setup Slack = %0d ns",
            initial_slack
        );

        $display(
            "Minimum Clock Period = %0d ns",
            initial_period
        );

        $display(
            "Fmax = %0.2f MHz",
            initial_fmax
        );

        if (initial_slack < 0) begin
            $display(
                "STATUS = TIMING VIOLATION"
            );
        end
        else begin
            $display(
                "ERROR: EXPECTED INITIAL VIOLATION"
            );
            failed = failed + 1;
        end

        // ------------------------------------------------
        // Optimization stages
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("OPTIMIZATION STAGES");
        $display("-----------------------------------------------");

        $display("");
        $display(
            "Stage 1: Logic optimization"
        );
        $display(
            "11 ns -> 9 ns"
        );

        $display(
            "Stage 2: Logic restructuring"
        );
        $display(
            "9 ns -> 8 ns"
        );

        $display(
            "Stage 3: Pipeline/register optimization"
        );
        $display(
            "8 ns -> 7 ns"
        );

        $display(
            "Stage 4: Further optimization"
        );
        $display(
            "7 ns -> 6 ns"
        );

        // ------------------------------------------------
        // Final design
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("FINAL OPTIMIZED DESIGN");
        $display("-----------------------------------------------");

        $display(
            "Critical Path = %0d ns",
            optimized_delay
        );

        $display(
            "Setup Slack = %0d ns",
            final_slack
        );

        $display(
            "Minimum Clock Period = %0d ns",
            final_period
        );

        $display(
            "Fmax = %0.2f MHz",
            final_fmax
        );

        if (final_slack > 0) begin
            $display(
                "STATUS = TIMING CLOSED"
            );
        end
        else begin
            $display(
                "ERROR: TIMING NOT CLOSED"
            );
            failed = failed + 1;
        end

        // ------------------------------------------------
        // Improvement analysis
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("TIMING IMPROVEMENT");
        $display("-----------------------------------------------");

        $display(
            "Slack Improvement = %0d ns",
            final_slack - initial_slack
        );

        $display(
            "Critical Path Reduction = %0d ns",
            initial_delay - optimized_delay
        );

        $display(
            "Fmax Improvement = %0.2f MHz",
            final_fmax - initial_fmax
        );

        // ------------------------------------------------
        // Verification
        // ------------------------------------------------

        if (initial_slack == -3) begin
            $display(
                "CHECK 1: INITIAL SLACK CORRECT"
            );
            passed = passed + 1;
        end
        else begin
            $display(
                "CHECK 1: FAIL"
            );
            failed = failed + 1;
        end

        if (final_slack == 2) begin
            $display(
                "CHECK 2: FINAL SLACK CORRECT"
            );
            passed = passed + 1;
        end
        else begin
            $display(
                "CHECK 2: FAIL"
            );
            failed = failed + 1;
        end

        if ((initial_delay - optimized_delay) == 5) begin
            $display(
                "CHECK 3: PATH REDUCTION CORRECT"
            );
            passed = passed + 1;
        end
        else begin
            $display(
                "CHECK 3: FAIL"
            );
            failed = failed + 1;
        end

        if (final_period == 8) begin
            $display(
                "CHECK 4: FINAL PERIOD CORRECT"
            );
            passed = passed + 1;
        end
        else begin
            $display(
                "CHECK 4: FAIL"
            );
            failed = failed + 1;
        end

        if (final_fmax > initial_fmax) begin
            $display(
                "CHECK 5: FMAX IMPROVEMENT VERIFIED"
            );
            passed = passed + 1;
        end
        else begin
            $display(
                "CHECK 5: FAIL"
            );
            failed = failed + 1;
        end

        // ------------------------------------------------
        // Final verification
        // ------------------------------------------------

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display(
            "INITIAL SLACK = %0d ns",
            initial_slack
        );

        $display(
            "FINAL SLACK = %0d ns",
            final_slack
        );

        $display(
            "INITIAL FMAX = %0.2f MHz",
            initial_fmax
        );

        $display(
            "FINAL FMAX = %0.2f MHz",
            final_fmax
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