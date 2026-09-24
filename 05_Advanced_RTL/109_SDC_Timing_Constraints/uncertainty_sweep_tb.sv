`timescale 1ns/1ps

module uncertainty_sweep_tb;

    real clock_period;
    real input_delay;
    real uncertainty;
    real available_window;

    integer passed;
    integer failed;

    task automatic analyze_uncertainty;
        input real u;
        real window;

        begin

            window = clock_period - u - input_delay;

            $display("");
            $display("-----------------------------------------------");
            $display("Clock Uncertainty = %0.2f ns", u);
            $display("Available Timing Window = %0.2f ns", window);

            if (window >= 0.0) begin
                $display("STATUS = VALID TIMING WINDOW");
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
        input_delay  = 2.0;

        $display("");
        $display("================================================");
        $display("          CLOCK UNCERTAINTY ANALYSIS");
        $display("================================================");

        $display("");
        $display("Clock Period = %0.2f ns", clock_period);
        $display("Input Delay  = %0.2f ns", input_delay);

        $display("");
        $display("Equation:");
        $display(
            "Available Window = Tclk - Uncertainty - Input Delay"
        );

        analyze_uncertainty(0.0);
        analyze_uncertainty(0.5);
        analyze_uncertainty(1.0);
        analyze_uncertainty(1.5);
        analyze_uncertainty(2.0);

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