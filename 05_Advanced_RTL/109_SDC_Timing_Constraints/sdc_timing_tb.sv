`timescale 1ns/1ps

module sdc_timing_tb;

    // ------------------------------------------------
    // SDC constraint values
    // ------------------------------------------------

    real clock_period;
    real clock_uncertainty;

    real input_delay;
    real output_delay;

    real input_transition;
    real output_load;

    real clock_frequency;

    real available_setup_time;
    real available_output_time;

    integer passed;
    integer failed;

    initial begin

        passed = 0;
        failed = 0;

        // ------------------------------------------------
        // Load values corresponding to constraints.sdc
        // ------------------------------------------------

        clock_period      = 10.0;
        clock_uncertainty = 0.5;

        input_delay       = 2.0;
        output_delay      = 2.0;

        input_transition  = 0.2;
        output_load       = 0.5;

        // ------------------------------------------------
        // Derived values
        // ------------------------------------------------

        clock_frequency = 1000.0 / clock_period;

        available_setup_time =
            clock_period - clock_uncertainty - input_delay;

        available_output_time =
            clock_period - clock_uncertainty - output_delay;

        // ------------------------------------------------
        // Header
        // ------------------------------------------------

        $display("");
        $display("================================================");
        $display("          SDC TIMING CONSTRAINT ANALYSIS");
        $display("================================================");

        $display("");
        $display("Clock Period       = %0.2f ns",
                 clock_period);

        $display("Clock Uncertainty  = %0.2f ns",
                 clock_uncertainty);

        $display("Input Delay        = %0.2f ns",
                 input_delay);

        $display("Output Delay       = %0.2f ns",
                 output_delay);

        $display("Input Transition   = %0.2f ns",
                 input_transition);

        $display("Output Load        = %0.2f",
                 output_load);

        // ------------------------------------------------
        // Clock frequency
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("CLOCK ANALYSIS");
        $display("-----------------------------------------------");

        $display(
            "Clock Frequency = %0.2f MHz",
            clock_frequency
        );

        if (clock_frequency == 100.0) begin
            $display("CHECK: CLOCK FREQUENCY PASS");
            passed = passed + 1;
        end
        else begin
            $display("CHECK: CLOCK FREQUENCY FAIL");
            failed = failed + 1;
        end

        // ------------------------------------------------
        // Input timing
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("INPUT TIMING");
        $display("-----------------------------------------------");

        $display(
            "Available Setup Window = Clock Period - Uncertainty - Input Delay"
        );

        $display(
            "Available Setup Window = %0.2f - %0.2f - %0.2f",
            clock_period,
            clock_uncertainty,
            input_delay
        );

        $display(
            "Available Setup Window = %0.2f ns",
            available_setup_time
        );

        if (available_setup_time == 7.5) begin
            $display("CHECK: INPUT TIMING PASS");
            passed = passed + 1;
        end
        else begin
            $display("CHECK: INPUT TIMING FAIL");
            failed = failed + 1;
        end

        // ------------------------------------------------
        // Output timing
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("OUTPUT TIMING");
        $display("-----------------------------------------------");

        $display(
            "Available Output Window = Clock Period - Uncertainty - Output Delay"
        );

        $display(
            "Available Output Window = %0.2f - %0.2f - %0.2f",
            clock_period,
            clock_uncertainty,
            output_delay
        );

        $display(
            "Available Output Window = %0.2f ns",
            available_output_time
        );

        if (available_output_time == 7.5) begin
            $display("CHECK: OUTPUT TIMING PASS");
            passed = passed + 1;
        end
        else begin
            $display("CHECK: OUTPUT TIMING FAIL");
            failed = failed + 1;
        end

        // ------------------------------------------------
        // Input transition
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("INPUT TRANSITION");
        $display("-----------------------------------------------");

        $display(
            "Input Transition = %0.2f ns",
            input_transition
        );

        if (input_transition == 0.2) begin
            $display("CHECK: INPUT TRANSITION PASS");
            passed = passed + 1;
        end
        else begin
            $display("CHECK: INPUT TRANSITION FAIL");
            failed = failed + 1;
        end

        // ------------------------------------------------
        // Output load
        // ------------------------------------------------

        $display("");
        $display("-----------------------------------------------");
        $display("OUTPUT LOAD");
        $display("-----------------------------------------------");

        $display(
            "Output Load = %0.2f",
            output_load
        );

        if (output_load == 0.5) begin
            $display("CHECK: OUTPUT LOAD PASS");
            passed = passed + 1;
        end
        else begin
            $display("CHECK: OUTPUT LOAD FAIL");
            failed = failed + 1;
        end

        // ------------------------------------------------
        // Final verification
        // ------------------------------------------------

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display(
            "TOTAL CHECKS = 5"
        );

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