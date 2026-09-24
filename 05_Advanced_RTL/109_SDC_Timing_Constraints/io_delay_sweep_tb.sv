`timescale 1ns/1ps

module io_delay_sweep_tb;

    real clock_period;
    real clock_uncertainty;

    real delay_value;
    real input_window;
    real output_window;

    integer passed;
    integer failed;

    task automatic analyze_delay;
        input real d;

        real in_window;
        real out_window;

        begin

            in_window =
                clock_period -
                clock_uncertainty -
                d;

            out_window =
                clock_period -
                clock_uncertainty -
                d;

            $display("");
            $display("-----------------------------------------------");
            $display("Delay = %0.2f ns", d);

            $display(
                "Input Timing Window  = %0.2f ns",
                in_window
            );

            $display(
                "Output Timing Window = %0.2f ns",
                out_window
            );

            if ((in_window >= 0.0) &&
                (out_window >= 0.0)) begin

                $display("STATUS = VALID TIMING WINDOWS");
                passed = passed + 1;

            end
            else begin

                $display("STATUS = INVALID TIMING WINDOW");
                failed = failed + 1;

            end

        end
    endtask


    initial begin

        passed = 0;
        failed = 0;

        clock_period = 10.0;
        clock_uncertainty = 0.5;

        $display("");
        $display("================================================");
        $display("       INPUT / OUTPUT DELAY ANALYSIS");
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
        $display("Input Timing:");
        $display(
            "Window = Tclk - Uncertainty - Input Delay"
        );

        $display("");
        $display("Output Timing:");
        $display(
            "Window = Tclk - Uncertainty - Output Delay"
        );

        analyze_delay(0.0);
        analyze_delay(1.0);
        analyze_delay(2.0);
        analyze_delay(3.0);
        analyze_delay(4.0);

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display("TOTAL CHECKS = 5");

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