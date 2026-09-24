`timescale 1ns/1ps

module critical_path_tb;

    parameter integer TCLK   = 10;
    parameter integer TCQ    = 1;
    parameter integer TSETUP = 1;

    integer path1;
    integer path2;
    integer path3;
    integer path4;

    integer required_path;
    integer critical_path;
    integer critical_delay;
    integer critical_slack;

    integer slack1;
    integer slack2;
    integer slack3;
    integer slack4;

    integer passed;
    integer failed;

    initial begin

        passed = 0;
        failed = 0;

        // ------------------------------------------------
        // Path delays
        // ------------------------------------------------

        path1 = 3;
        path2 = 5;
        path3 = 7;
        path4 = 4;

        // ------------------------------------------------
        // Maximum allowed combinational delay
        // ------------------------------------------------

        required_path = TCLK - TCQ - TSETUP;

        // ------------------------------------------------
        // Calculate path slacks
        // ------------------------------------------------

        slack1 = required_path - path1;
        slack2 = required_path - path2;
        slack3 = required_path - path3;
        slack4 = required_path - path4;

        // ------------------------------------------------
        // Find critical path
        // ------------------------------------------------

        critical_path  = 1;
        critical_delay = path1;

        if (path2 > critical_delay) begin
            critical_delay = path2;
            critical_path = 2;
        end

        if (path3 > critical_delay) begin
            critical_delay = path3;
            critical_path = 3;
        end

        if (path4 > critical_delay) begin
            critical_delay = path4;
            critical_path = 4;
        end

        // ------------------------------------------------
        // Calculate critical path slack
        // ------------------------------------------------

        critical_slack = required_path - critical_delay;

        // ------------------------------------------------
        // Header
        // ------------------------------------------------

        $display("");
        $display("================================================");
        $display("             CRITICAL PATH ANALYSIS");
        $display("================================================");

        $display("");
        $display("Clock Period      = %0d ns", TCLK);
        $display("Clock-to-Q Delay  = %0d ns", TCQ);
        $display("Setup Time        = %0d ns", TSETUP);

        $display("");
        $display("Maximum Allowed Combinational Delay:");

        $display(
            "Tclk - Tcq - Tsetup = %0d - %0d - %0d",
            TCLK,
            TCQ,
            TSETUP
        );

        $display(
            "Maximum Allowed Delay = %0d ns",
            required_path
        );

        // ------------------------------------------------
        // Path 1
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("PATH 1");
        $display("-----------------------------------------------");

        $display(
            "Combinational Delay = %0d ns",
            path1
        );

        $display(
            "Setup Slack = %0d ns",
            slack1
        );

        if (slack1 >= 0)
            $display("STATUS = TIMING MET");
        else
            $display("STATUS = SETUP VIOLATION");

        // ------------------------------------------------
        // Path 2
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("PATH 2");
        $display("-----------------------------------------------");

        $display(
            "Combinational Delay = %0d ns",
            path2
        );

        $display(
            "Setup Slack = %0d ns",
            slack2
        );

        if (slack2 >= 0)
            $display("STATUS = TIMING MET");
        else
            $display("STATUS = SETUP VIOLATION");

        // ------------------------------------------------
        // Path 3
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("PATH 3");
        $display("-----------------------------------------------");

        $display(
            "Combinational Delay = %0d ns",
            path3
        );

        $display(
            "Setup Slack = %0d ns",
            slack3
        );

        if (slack3 >= 0)
            $display("STATUS = TIMING MET");
        else
            $display("STATUS = SETUP VIOLATION");

        // ------------------------------------------------
        // Path 4
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("PATH 4");
        $display("-----------------------------------------------");

        $display(
            "Combinational Delay = %0d ns",
            path4
        );

        $display(
            "Setup Slack = %0d ns",
            slack4
        );

        if (slack4 >= 0)
            $display("STATUS = TIMING MET");
        else
            $display("STATUS = SETUP VIOLATION");

        // ------------------------------------------------
        // Critical path result
        // ------------------------------------------------

        $display("");
        $display("================================================");
        $display("             CRITICAL PATH RESULT");
        $display("================================================");

        $display(
            "CRITICAL PATH = PATH %0d",
            critical_path
        );

        $display(
            "CRITICAL DELAY = %0d ns",
            critical_delay
        );

        $display(
            "CRITICAL PATH SLACK = %0d ns",
            critical_slack
        );

        // ------------------------------------------------
        // Verification Check 1
        // ------------------------------------------------

        if (critical_path == 3) begin
            $display("CHECK 1: CRITICAL PATH CORRECT");
            passed = passed + 1;
        end
        else begin
            $display("CHECK 1: ERROR - WRONG CRITICAL PATH");
            failed = failed + 1;
        end

        // ------------------------------------------------
        // Verification Check 2
        // ------------------------------------------------

        if (critical_delay == 7) begin
            $display("CHECK 2: CRITICAL DELAY CORRECT");
            passed = passed + 1;
        end
        else begin
            $display("CHECK 2: ERROR - WRONG CRITICAL DELAY");
            failed = failed + 1;
        end

        // ------------------------------------------------
        // Verification Check 3
        // ------------------------------------------------

        if (critical_slack == 1) begin
            $display("CHECK 3: CRITICAL SLACK CORRECT");
            passed = passed + 1;
        end
        else begin
            $display("CHECK 3: ERROR - WRONG CRITICAL SLACK");
            failed = failed + 1;
        end

        // ------------------------------------------------
        // Final verification
        // ------------------------------------------------

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display("TOTAL CHECKS = 3");

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
            $display("OVERALL RESULT = PASS");
        else
            $display("OVERALL RESULT = FAIL");

        $display("================================================");

        $finish;

    end

endmodule