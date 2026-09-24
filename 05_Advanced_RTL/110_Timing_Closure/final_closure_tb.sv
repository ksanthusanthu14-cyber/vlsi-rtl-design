`timescale 1ns/1ps

module final_closure_tb;

    real tcq;
    real tsetup;
    real critical_path;
    real allowed_delay;
    real clock_period;
    real slack;
    real fmax;

    integer total_checks;
    integer passed_checks;
    integer failed_checks;

    task automatic analyze_timing;
        input real period;
        input real path;
        input integer case_no;

        real local_slack;
        real local_fmax;
        real minimum_period;

        begin
            minimum_period = tcq + path + tsetup;
            local_slack = period - minimum_period;
            local_fmax = 1000.0 / minimum_period;

            $display("-----------------------------------------------");
            $display("CASE %0d", case_no);
            $display("Clock Period     = %.2f ns", period);
            $display("Critical Path    = %.2f ns", path);
            $display("Minimum Period   = %.2f ns", minimum_period);
            $display("Setup Slack      = %.2f ns", local_slack);
            $display("Fmax             = %.2f MHz", local_fmax);

            if (local_slack > 0.0) begin
                $display("STATUS           = TIMING MET WITH MARGIN");
            end
            else if (local_slack == 0.0) begin
                $display("STATUS           = ZERO SLACK / BOUNDARY");
            end
            else begin
                $display("STATUS           = TIMING VIOLATION");
            end

            total_checks = total_checks + 1;

            if ((case_no == 1) && (local_slack > 0.0)) begin
                $display("CHECK = PASS");
                passed_checks = passed_checks + 1;
            end
            else if ((case_no == 2) && (local_slack == 0.0)) begin
                $display("CHECK = PASS");
                passed_checks = passed_checks + 1;
            end
            else if ((case_no == 3) && (local_slack < 0.0)) begin
                $display("CHECK = PASS");
                passed_checks = passed_checks + 1;
            end
            else begin
                $display("CHECK = FAIL");
                failed_checks = failed_checks + 1;
            end
        end
    endtask

    initial begin

        tcq = 1.0;
        tsetup = 1.0;
        critical_path = 6.0;
        allowed_delay = 8.0;

        total_checks = 0;
        passed_checks = 0;
        failed_checks = 0;

        $display("");
        $display("================================================");
        $display("       FINAL TIMING CLOSURE VERIFICATION");
        $display("================================================");

        $display("");
        $display("Optimized Critical Path = %.2f ns", critical_path);
        $display("Clock-to-Q              = %.2f ns", tcq);
        $display("Setup Time              = %.2f ns", tsetup);
        $display("Allowed Delay           = %.2f ns", allowed_delay);

        /*
         * CASE 1
         * Clock period = 10 ns
         *
         * Minimum required period:
         * 1 + 6 + 1 = 8 ns
         *
         * Slack:
         * 10 - 8 = +2 ns
         */
        analyze_timing(10.0, critical_path, 1);

        /*
         * CASE 2
         * Clock period = 8 ns
         *
         * Slack:
         * 8 - 8 = 0 ns
         */
        analyze_timing(8.0, critical_path, 2);

        /*
         * CASE 3
         * Clock period = 7 ns
         *
         * Slack:
         * 7 - 8 = -1 ns
         */
        analyze_timing(7.0, critical_path, 3);

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display("Optimized Critical Path = %.2f ns", critical_path);
        $display("Minimum Clock Period    = %.2f ns",
                 tcq + critical_path + tsetup);
        $display("Maximum Frequency       = %.2f MHz",
                 1000.0 / (tcq + critical_path + tsetup));

        $display("");
        $display("TOTAL CHECKS = %0d", total_checks);
        $display("PASSED CHECKS = %0d", passed_checks);
        $display("FAILED CHECKS = %0d", failed_checks);

        if (failed_checks == 0)
            $display("");
        $display("OVERALL RESULT = %s",
                 (failed_checks == 0) ? "PASS" : "FAIL");

        $display("================================================");

        $finish;
    end

endmodule