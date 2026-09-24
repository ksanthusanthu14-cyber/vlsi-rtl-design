`timescale 1ns/1ps

module hold_sweep_tb;

    parameter integer TCQ_MIN = 1;
    parameter integer THOLD   = 1;

    integer comb_delay;
    integer hold_slack;

    integer passed;
    integer failed;

    task automatic analyze_hold;
        input integer delay;
        begin

            hold_slack = TCQ_MIN + delay - THOLD;

            $display("");
            $display("-----------------------------------------------");
            $display("Tcomb(min) = %0d ns", delay);
            $display("Tcq(min)   = %0d ns", TCQ_MIN);
            $display("Thold      = %0d ns", THOLD);
            $display("Hold Slack = %0d ns", hold_slack);

            if (delay > 0) begin

                if (hold_slack > 0) begin
                    $display("STATUS = TIMING MET");
                    passed = passed + 1;
                end
                else begin
                    $display("ERROR: EXPECTED POSITIVE HOLD SLACK");
                    failed = failed + 1;
                end

            end
            else if (delay == 0) begin

                if (hold_slack == 0) begin
                    $display("STATUS = ZERO-SLACK BOUNDARY");
                    passed = passed + 1;
                end
                else begin
                    $display("ERROR: EXPECTED ZERO HOLD SLACK");
                    failed = failed + 1;
                end

            end
            else begin

                if (hold_slack < 0) begin
                    $display("STATUS = HOLD VIOLATION");
                    passed = passed + 1;
                end
                else begin
                    $display("ERROR: EXPECTED NEGATIVE HOLD SLACK");
                    failed = failed + 1;
                end

            end

        end
    endtask


    initial begin

        passed = 0;
        failed = 0;

        $display("");
        $display("================================================");
        $display("             HOLD SLACK SWEEP");
        $display("================================================");

        $display("");
        $display("Tcq(min) = %0d ns", TCQ_MIN);
        $display("Thold    = %0d ns", THOLD);

        $display("");
        $display("Equation:");
        $display("Hold Slack = Tcq(min) + Tcomb(min) - Thold");

        analyze_hold(2);
        analyze_hold(1);
        analyze_hold(0);
        analyze_hold(-1);

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display("TOTAL CHECKS = 4");

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