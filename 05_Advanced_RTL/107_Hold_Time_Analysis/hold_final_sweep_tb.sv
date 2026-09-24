`timescale 1ns/1ps

module hold_final_sweep_tb;

    real TCQ_MIN;
    real THOLD;

    real comb_delay;
    real hold_slack;
    real minimum_comb_delay;

    integer passed;
    integer failed;

    task automatic analyze_delay;
        input real delay;

        begin

            hold_slack = TCQ_MIN + delay - THOLD;

            $display("");
            $display("-----------------------------------------------");
            $display("Tcomb(min) = %0.2f ns", delay);
            $display("Hold Slack = %0.2f ns", hold_slack);

            if (delay < minimum_comb_delay) begin

                if (hold_slack < 0.0) begin
                    $display("STATUS = HOLD VIOLATION");
                    passed = passed + 1;
                end
                else begin
                    $display("ERROR: EXPECTED HOLD VIOLATION");
                    failed = failed + 1;
                end

            end
            else if (delay == minimum_comb_delay) begin

                if (hold_slack == 0.0) begin
                    $display("STATUS = ZERO-SLACK BOUNDARY");
                    passed = passed + 1;
                end
                else begin
                    $display("ERROR: EXPECTED ZERO SLACK");
                    failed = failed + 1;
                end

            end
            else begin

                if (hold_slack > 0.0) begin
                    $display("STATUS = HOLD TIMING MET");
                    passed = passed + 1;
                end
                else begin
                    $display("ERROR: EXPECTED POSITIVE SLACK");
                    failed = failed + 1;
                end

            end

        end
    endtask


    initial begin

        passed = 0;
        failed = 0;

        TCQ_MIN = 1.0;
        THOLD   = 2.0;

        minimum_comb_delay = THOLD - TCQ_MIN;

        $display("");
        $display("================================================");
        $display("        FINAL HOLD-TIME DELAY SWEEP");
        $display("================================================");

        $display("");
        $display("Tcq(min) = %0.2f ns", TCQ_MIN);
        $display("Thold    = %0.2f ns", THOLD);

        $display("");
        $display("Required Minimum Combinational Delay:");
        $display(
            "Tcomb(min) = Thold - Tcq(min)"
        );

        $display(
            "Tcomb(min) = %0.2f - %0.2f",
            THOLD,
            TCQ_MIN
        );

        $display(
            "Required Tcomb(min) = %0.2f ns",
            minimum_comb_delay
        );

        $display("");
        $display("-----------------------------------------------");
        $display("COMPREHENSIVE DELAY SWEEP");
        $display("-----------------------------------------------");

        analyze_delay(0.0);
        analyze_delay(0.5);
        analyze_delay(1.0);
        analyze_delay(1.5);
        analyze_delay(2.0);
        analyze_delay(3.0);

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display(
            "REQUIRED MINIMUM TCOMB = %0.2f ns",
            minimum_comb_delay
        );

        $display("TOTAL CHECKS = 6");

        $display(
            "PASSED CHECKS = %0d",
            passed
        );

        $display(
            "FAILED CHECKS = %0d",
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