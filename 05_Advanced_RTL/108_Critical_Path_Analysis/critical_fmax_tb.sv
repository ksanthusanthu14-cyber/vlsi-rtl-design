`timescale 1ns/1ps

module critical_fmax_tb;

    parameter integer TCQ   = 1;
    parameter integer TSETUP = 1;

    real critical_delay;
    real minimum_period;
    real fmax_mhz;

    integer passed;
    integer failed;

    task automatic analyze_path;
        input real delay;
        real period;
        real frequency;

        begin

            period = TCQ + delay + TSETUP;

            frequency = 1000.0 / period;

            $display("");
            $display("-----------------------------------------------");
            $display("Critical Path Delay = %0.2f ns", delay);
            $display("Minimum Clock Period = %0.2f ns", period);
            $display("Maximum Frequency = %0.2f MHz", frequency);

            if (period > 0.0 && frequency > 0.0) begin
                $display("STATUS = VALID FMAX");
                passed = passed + 1;
            end
            else begin
                $display("ERROR: INVALID TIMING");
                failed = failed + 1;
            end

        end
    endtask


    initial begin

        passed = 0;
        failed = 0;

        critical_delay = 7.0;

        minimum_period = TCQ + critical_delay + TSETUP;

        fmax_mhz = 1000.0 / minimum_period;

        $display("");
        $display("================================================");
        $display("        CRITICAL PATH FMAX ANALYSIS");
        $display("================================================");

        $display("");
        $display("Clock-to-Q Delay = %0d ns", TCQ);
        $display("Setup Time = %0d ns", TSETUP);

        $display("");
        $display("Reference Critical Path = %0.2f ns", critical_delay);

        $display("");
        $display("Minimum Clock Period:");
        $display("Tclk(min) = Tcq + Tcritical + Tsetup");

        $display(
            "Tclk(min) = %0d + %0.2f + %0d",
            TCQ,
            critical_delay,
            TSETUP
        );

        $display(
            "Tclk(min) = %0.2f ns",
            minimum_period
        );

        $display("");
        $display("Maximum Clock Frequency:");
        $display("Fmax = 1 / Tclk(min)");

        $display(
            "Fmax = %0.2f MHz",
            fmax_mhz
        );

        $display("");
        $display("-----------------------------------------------");
        $display("CRITICAL PATH DELAY SWEEP");
        $display("-----------------------------------------------");

        analyze_path(3.0);
        analyze_path(5.0);
        analyze_path(7.0);
        analyze_path(8.0);
        analyze_path(9.0);

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display(
            "REFERENCE CRITICAL PATH = %0.2f ns",
            critical_delay
        );

        $display(
            "REFERENCE MIN PERIOD = %0.2f ns",
            minimum_period
        );

        $display(
            "REFERENCE FMAX = %0.2f MHz",
            fmax_mhz
        );

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