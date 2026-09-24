`timescale 1ns/1ps

module sdc_final_tb;

    real clock_period;
    real clock_uncertainty;

    real maximum_delay;
    real timing_window;

    integer passed;
    integer failed;

    task automatic analyze_constraint;
        input integer case_number;
        input real delay;

        real window;

        begin

            window =
                clock_period -
                clock_uncertainty -
                delay;

            $display("");
            $display("================================================");
            $display("CASE %0d", case_number);
            $display("================================================");

            $display(
                "I/O Delay = %0.2f ns",
                delay
            );

            $display(
                "Timing Window = %0.2f ns",
                window
            );

            if (delay < maximum_delay) begin

                if (window > 0.0) begin
                    $display("STATUS = VALID TIMING WINDOW");
                    passed = passed + 1;
                end
                else begin
                    $display("ERROR: EXPECTED POSITIVE WINDOW");
                    failed = failed + 1;
                end

            end
            else if (delay == maximum_delay) begin

                if (window == 0.0) begin
                    $display("STATUS = ZERO-SLACK BOUNDARY");
                    passed = passed + 1;
                end
                else begin
                    $display("ERROR: EXPECTED ZERO WINDOW");
                    failed = failed + 1;
                end

            end
            else begin

                if (window < 0.0) begin
                    $display("STATUS = INVALID TIMING CONSTRAINT");
                    passed = passed + 1;
                end
                else begin
                    $display("ERROR: EXPECTED NEGATIVE WINDOW");
                    failed = failed + 1;
                end

            end

        end
    endtask


    initial begin

        passed = 0;
        failed = 0;

        clock_period = 10.0;
        clock_uncertainty = 0.5;

        maximum_delay =
            clock_period -
            clock_uncertainty;

        $display("");
        $display("================================================");
        $display("        FINAL SDC CONSTRAINT ANALYSIS");
        $display("================================================");

        $display("");
        $display(
            "Clock Period = %0.2f ns",
            clock_period
        );

        $display(
            "Clock Uncertainty = %0.2f ns",
            clock_uncertainty
        );

        $display("");
        $display(
            "Maximum Allowable I/O Delay = %0.2f ns",
            maximum_delay
        );

        $display("");
        $display("Equation:");
        $display(
            "Maximum Delay = Tclk - Uncertainty"
        );

        analyze_constraint(1, 8.0);
        analyze_constraint(2, 9.0);
        analyze_constraint(3, 9.5);
        analyze_constraint(4, 10.0);

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display(
            "MAXIMUM ALLOWABLE DELAY = %0.2f ns",
            maximum_delay
        );

        $display("TOTAL CASES = 4");

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