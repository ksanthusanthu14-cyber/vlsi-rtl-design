`timescale 1ns/1ps

module hold_analysis_tb;

    parameter integer TCQ_MIN   = 1;
    parameter integer TCOMB_MIN = 2;
    parameter integer THOLD     = 1;

    integer arrival_delay;
    integer required_delay;
    integer hold_slack;

    integer passed;
    integer failed;

    initial begin

        passed = 0;
        failed = 0;

        // Earliest data arrival after launch
        arrival_delay = TCQ_MIN + TCOMB_MIN;

        // Minimum delay required to satisfy hold
        required_delay = THOLD;

        // Hold slack
        hold_slack = arrival_delay - required_delay;

        $display("");
        $display("================================================");
        $display("             HOLD TIME ANALYSIS");
        $display("================================================");

        $display("");
        $display("Clock-to-Q Minimum Delay = %0d ns", TCQ_MIN);
        $display("Minimum Combinational Delay = %0d ns", TCOMB_MIN);
        $display("Hold Time = %0d ns", THOLD);

        $display("");
        $display("Hold Timing Equation:");
        $display("Tcq(min) + Tcomb(min) >= Thold");

        $display("");
        $display("Earliest Data Arrival:");
        $display(
            "Arrival = %0d + %0d",
            TCQ_MIN,
            TCOMB_MIN
        );

        $display(
            "Arrival = %0d ns",
            arrival_delay
        );

        $display("");
        $display("Required Minimum Delay:");
        $display(
            "Required = %0d ns",
            required_delay
        );

        $display("");
        $display("Hold Slack:");
        $display(
            "Slack = Arrival - Required"
        );

        $display(
            "Slack = %0d - %0d",
            arrival_delay,
            required_delay
        );

        $display(
            "Hold Slack = %0d ns",
            hold_slack
        );

        $display("");

        if (hold_slack > 0) begin
            $display("STATUS = TIMING MET");
            passed = passed + 1;
        end
        else if (hold_slack == 0) begin
            $display("STATUS = ZERO-SLACK BOUNDARY");
            passed = passed + 1;
        end
        else begin
            $display("STATUS = HOLD VIOLATION");
            failed = failed + 1;
        end

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

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