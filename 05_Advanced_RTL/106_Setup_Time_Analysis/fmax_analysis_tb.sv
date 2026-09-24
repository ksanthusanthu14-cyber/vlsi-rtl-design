`timescale 1ns/1ps

module fmax_analysis_tb;

    parameter integer TCQ   = 1;
    parameter integer TCOMB = 3;
    parameter integer TSETUP = 1;

    real total_delay;
    real fmax_mhz;

    integer passed;
    integer failed;

    task automatic analyze_fmax;
        input integer comb_delay;
        real path_delay;
        real required_period;
        real frequency_mhz;
        begin
            path_delay = TCQ + comb_delay + TSETUP;

            required_period = path_delay;

            frequency_mhz = 1000.0 / required_period;

            $display("");
            $display("-----------------------------------------------");
            $display("Combinational Delay = %0d ns", comb_delay);
            $display("Tcq                  = %0d ns", TCQ);
            $display("Tsetup               = %0d ns", TSETUP);
            $display("Minimum Clock Period = %0.2f ns", required_period);
            $display("Maximum Frequency    = %0.2f MHz", frequency_mhz);

            if (required_period > 0) begin
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

        total_delay = TCQ + TCOMB + TSETUP;

        fmax_mhz = 1000.0 / total_delay;

        $display("");
        $display("================================================");
        $display("          MAXIMUM CLOCK FREQUENCY ANALYSIS");
        $display("================================================");

        $display("");
        $display("Clock-to-Q Delay = %0d ns", TCQ);
        $display("Combinational Delay = %0d ns", TCOMB);
        $display("Setup Time = %0d ns", TSETUP);

        $display("");
        $display("Timing Equation:");
        $display("Tclk >= Tcq + Tcomb + Tsetup");

        $display("");
        $display("Minimum Clock Period:");
        $display(
            "Tclk(min) = %0d + %0d + %0d",
            TCQ,
            TCOMB,
            TSETUP
        );

        $display(
            "Tclk(min) = %0.2f ns",
            total_delay
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
        $display("FREQUENCY ANALYSIS");
        $display("-----------------------------------------------");

        analyze_fmax(2);
        analyze_fmax(3);
        analyze_fmax(4);
        analyze_fmax(6);
        analyze_fmax(8);

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display(
            "REFERENCE PATH DELAY = %0.2f ns",
            total_delay
        );

        $display(
            "REFERENCE FMAX       = %0.2f MHz",
            fmax_mhz
        );

        $display(
            "TOTAL CHECKS         = 5"
        );

        $display(
            "PASSED CHECKS        = %0d",
            passed
        );

        $display(
            "FAILED CHECKS        = %0d",
            failed
        );

        $display("");

        if (failed == 0) begin
            $display("OVERALL RESULT = PASS");
        end
        else begin
            $display("OVERALL RESULT = FAIL");
        end

        $display("================================================");

        $finish;

    end

endmodule