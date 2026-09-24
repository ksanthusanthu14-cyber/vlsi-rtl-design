`timescale 1ns/1ps

// ============================================================
// PROJECT 106 - SETUP TIME ANALYSIS
// TIMING SWEEP
//
// Case 1 : Positive Slack
// Case 2 : Zero Slack
// Case 3 : Negative Slack
//
// Formula:
//
// Setup Slack = Tclk - (Tcq + Tcomb + Tsetup)
//
// ============================================================

module setup_sweep_tb;

    // ========================================================
    // COMMON PATH PARAMETERS
    // ========================================================

    parameter integer TCQ    = 1;
    parameter integer TCOMB  = 3;
    parameter integer TSETUP = 1;

    integer required_path;
    integer slack;

    integer passed;
    integer failed;


    // ========================================================
    // TASK: ANALYZE TIMING CASE
    // ========================================================

    task automatic analyze_case;

        input integer case_number;
        input [8*30-1:0] case_name;
        input integer clock_period;
        input integer expected_type;

        begin

            required_path = TCQ + TCOMB + TSETUP;

            slack = clock_period - required_path;


            $display("");
            $display("------------------------------------------------");
            $display(
                "CASE %0d : %s",
                case_number,
                case_name
            );
            $display("------------------------------------------------");

            $display(
                "Clock Period       = %0d ns",
                clock_period
            );

            $display(
                "Clock-to-Q         = %0d ns",
                TCQ
            );

            $display(
                "Combinational      = %0d ns",
                TCOMB
            );

            $display(
                "Setup Time         = %0d ns",
                TSETUP
            );

            $display(
                "Required Path      = %0d ns",
                required_path
            );

            $display(
                "Setup Slack        = %0d ns",
                slack
            );


            // ------------------------------------------------
            // CASE TYPE
            //
            // expected_type:
            //
            // 0 = positive slack
            // 1 = zero slack
            // 2 = negative slack
            // ------------------------------------------------

            if (expected_type == 0) begin

                if (slack > 0) begin

                    $display(
                        "RESULT             = PASS"
                    );

                    $display(
                        "STATUS             = TIMING MET"
                    );

                    passed = passed + 1;

                end
                else begin

                    $display(
                        "RESULT             = FAIL"
                    );

                    failed = failed + 1;

                end

            end


            else if (expected_type == 1) begin

                if (slack == 0) begin

                    $display(
                        "RESULT             = PASS"
                    );

                    $display(
                        "STATUS             = ZERO-SLACK BOUNDARY"
                    );

                    passed = passed + 1;

                end
                else begin

                    $display(
                        "RESULT             = FAIL"
                    );

                    failed = failed + 1;

                end

            end


            else begin

                if (slack < 0) begin

                    $display(
                        "RESULT             = PASS"
                    );

                    $display(
                        "STATUS             = SETUP VIOLATION DETECTED"
                    );

                    passed = passed + 1;

                end
                else begin

                    $display(
                        "RESULT             = FAIL"
                    );

                    failed = failed + 1;

                end

            end

        end

    endtask


    // ========================================================
    // MAIN
    // ========================================================

    initial begin

        passed = 0;
        failed = 0;


        // ====================================================
        // HEADER
        // ====================================================

        $display("");
        $display("================================================");
        $display("       PROJECT 106 - SETUP TIME ANALYSIS");
        $display("              TIMING SWEEP");
        $display("================================================");


        // ====================================================
        // CASE 1
        // ====================================================

        analyze_case(
            1,
            "POSITIVE SLACK",
            10,
            0
        );


        // ====================================================
        // CASE 2
        // ====================================================

        analyze_case(
            2,
            "ZERO SLACK",
            5,
            1
        );


        // ====================================================
        // CASE 3
        // ====================================================

        analyze_case(
            3,
            "NEGATIVE SLACK",
            4,
            2
        );


        // ====================================================
        // FINAL SUMMARY
        // ====================================================

        $display("");
        $display("================================================");
        $display("             TIMING SWEEP SUMMARY");
        $display("================================================");

        $display(
            "CASE 1 SLACK       = +5 ns"
        );

        $display(
            "CASE 2 SLACK       =  0 ns"
        );

        $display(
            "CASE 3 SLACK       = -1 ns"
        );

        $display("");

        $display(
            "POSITIVE SLACK     = TIMING MET"
        );

        $display(
            "ZERO SLACK         = TIMING BOUNDARY"
        );

        $display(
            "NEGATIVE SLACK     = SETUP VIOLATION"
        );

        $display("");

        $display(
            "PASSED CASES      = %0d",
            passed
        );

        $display(
            "FAILED CASES      = %0d",
            failed
        );


        if (failed == 0) begin

            $display("");
            $display(
                "OVERALL RESULT = PASS"
            );

        end
        else begin

            $display("");
            $display(
                "OVERALL RESULT = FAIL"
            );

        end


        $display("================================================");

        $finish;

    end

endmodule