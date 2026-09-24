`timescale 1ns/1ps

module critical_final_tb;

    parameter integer TCLK   = 10;
    parameter integer TCQ    = 1;
    parameter integer TSETUP = 1;

    integer allowed_delay;

    integer critical_path;
    integer critical_delay;
    integer critical_slack;

    integer passed;
    integer failed;

    task automatic analyze_case;
        input integer case_number;
        input integer p1;
        input integer p2;
        input integer p3;
        input integer p4;

        integer max_delay;
        integer max_path;
        integer slack;

        begin

            max_delay = p1;
            max_path = 1;

            if (p2 > max_delay) begin
                max_delay = p2;
                max_path = 2;
            end

            if (p3 > max_delay) begin
                max_delay = p3;
                max_path = 3;
            end

            if (p4 > max_delay) begin
                max_delay = p4;
                max_path = 4;
            end

            slack = allowed_delay - max_delay;

            $display("");
            $display("================================================");
            $display("CASE %0d", case_number);
            $display("================================================");

            $display("Path 1 = %0d ns", p1);
            $display("Path 2 = %0d ns", p2);
            $display("Path 3 = %0d ns", p3);
            $display("Path 4 = %0d ns", p4);

            $display("");
            $display("Critical Path = PATH %0d", max_path);
            $display("Critical Delay = %0d ns", max_delay);
            $display("Critical Slack = %0d ns", slack);

            if (slack > 0) begin

                $display("STATUS = TIMING MET");

            end
            else if (slack == 0) begin

                $display("STATUS = ZERO-SLACK BOUNDARY");

            end
            else begin

                $display("STATUS = SETUP VIOLATION");

            end

            // Case-specific verification

            if (case_number == 1) begin

                if (max_path == 3 &&
                    max_delay == 7 &&
                    slack == 1) begin

                    $display("CASE 1 CHECK = PASS");
                    passed = passed + 1;

                end
                else begin

                    $display("CASE 1 CHECK = FAIL");
                    failed = failed + 1;

                end

            end

            else if (case_number == 2) begin

                if (max_path == 3 &&
                    max_delay == 8 &&
                    slack == 0) begin

                    $display("CASE 2 CHECK = PASS");
                    passed = passed + 1;

                end
                else begin

                    $display("CASE 2 CHECK = FAIL");
                    failed = failed + 1;

                end

            end

            else if (case_number == 3) begin

                if (max_path == 3 &&
                    max_delay == 9 &&
                    slack == -1) begin

                    $display("CASE 3 CHECK = PASS");
                    passed = passed + 1;

                end
                else begin

                    $display("CASE 3 CHECK = FAIL");
                    failed = failed + 1;

                end

            end

        end

    endtask


    initial begin

        passed = 0;
        failed = 0;

        allowed_delay = TCLK - TCQ - TSETUP;

        $display("");
        $display("================================================");
        $display("       FINAL MULTI-PATH TIMING ANALYSIS");
        $display("================================================");

        $display("");
        $display("Clock Period = %0d ns", TCLK);
        $display("Clock-to-Q = %0d ns", TCQ);
        $display("Setup Time = %0d ns", TSETUP);

        $display("");
        $display(
            "Maximum Allowed Path Delay = %0d ns",
            allowed_delay
        );

        // Case 1: Timing met
        analyze_case(
            1,
            3,
            5,
            7,
            4
        );

        // Case 2: Zero slack
        analyze_case(
            2,
            3,
            6,
            8,
            5
        );

        // Case 3: Setup violation
        analyze_case(
            3,
            3,
            6,
            9,
            5
        );

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display("TOTAL CASES = 3");

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