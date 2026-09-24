`timescale 1ns/1ps

module hold_min_delay_tb;

    parameter integer TCQ_MIN = 1;
    parameter integer THOLD   = 2;

    integer minimum_comb_delay;
    integer passed;
    integer failed;

    task automatic analyze_delay;
        input integer delay;
        integer slack;

        begin

            slack = TCQ_MIN + delay - THOLD;

            $display("");
            $display("-----------------------------------------------");
            $display("Tcomb(min) = %0d ns", delay);
            $display("Hold Slack = %0d ns", slack);

            if (delay < minimum_comb_delay) begin

                if (slack < 0) begin
                    $display("STATUS = HOLD VIOLATION");
                    passed = passed + 1;
                end
                else begin
                    $display("ERROR: EXPECTED HOLD VIOLATION");
                    failed = failed + 1;
                end

            end
            else if (delay == minimum_comb_delay) begin

                if (slack == 0) begin
                    $display("STATUS = MINIMUM DELAY BOUNDARY");
                    passed = passed + 1;
                end
                else begin
                    $display("ERROR: EXPECTED ZERO SLACK");
                    failed = failed + 1;
                end

            end
            else begin

                if (slack > 0) begin
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

        minimum_comb_delay = THOLD - TCQ_MIN;

        $display("");
        $display("================================================");
        $display("       MINIMUM COMBINATIONAL DELAY ANALYSIS");
        $display("================================================");

        $display("");
        $display("Clock-to-Q Minimum = %0d ns", TCQ_MIN);
        $display("Hold Time          = %0d ns", THOLD);

        $display("");
        $display("Minimum Combinational Delay:");
        $display("Tcomb(min) = Thold - Tcq(min)");

        $display(
            "Tcomb(min) = %0d - %0d",
            THOLD,
            TCQ_MIN
        );

        $display(
            "Minimum Tcomb = %0d ns",
            minimum_comb_delay
        );

        $display("");
        $display("-----------------------------------------------");
        $display("DELAY ANALYSIS");
        $display("-----------------------------------------------");

        analyze_delay(0);
        analyze_delay(1);
        analyze_delay(2);

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display(
            "MINIMUM COMBINATIONAL DELAY = %0d ns",
            minimum_comb_delay
        );

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