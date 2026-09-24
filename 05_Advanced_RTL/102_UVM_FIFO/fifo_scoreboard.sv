class fifo_scoreboard;

    integer total_checks;
    integer passed_checks;
    integer failed_checks;

    integer read_checks;
    integer status_checks;
    integer overflow_checks;
    integer underflow_checks;


    // ============================================================
    // CONSTRUCTOR
    // ============================================================

    function new;
    begin

        total_checks    = 0;
        passed_checks   = 0;
        failed_checks   = 0;

        read_checks     = 0;
        status_checks   = 0;
        overflow_checks = 0;
        underflow_checks = 0;

    end
    endfunction


    // ============================================================
    // READ DATA CHECK
    // ============================================================

    task check_read;

        input [7:0] actual;
        input [7:0] expected;

        begin

            read_checks  = read_checks + 1;
            total_checks = total_checks + 1;

            if (actual === expected) begin

                passed_checks = passed_checks + 1;

                $display(
                    "PASS | READ DATA=%02h EXPECTED=%02h",
                    actual,
                    expected
                );

            end
            else begin

                failed_checks = failed_checks + 1;

                $display(
                    "FAIL | READ DATA=%02h EXPECTED=%02h",
                    actual,
                    expected
                );

            end

        end

    endtask


    // ============================================================
    // FULL / EMPTY STATUS CHECK
    // ============================================================

    task check_status;

        input actual_full;
        input actual_empty;

        input expected_full;
        input expected_empty;

        begin

            // ----------------------------------------------------
            // FULL
            // ----------------------------------------------------

            status_checks = status_checks + 1;
            total_checks  = total_checks + 1;

            if (actual_full === expected_full) begin

                passed_checks = passed_checks + 1;

                $display(
                    "PASS | FULL  DUT=%b EXPECTED=%b",
                    actual_full,
                    expected_full
                );

            end
            else begin

                failed_checks = failed_checks + 1;

                $display(
                    "FAIL | FULL  DUT=%b EXPECTED=%b",
                    actual_full,
                    expected_full
                );

            end


            // ----------------------------------------------------
            // EMPTY
            // ----------------------------------------------------

            status_checks = status_checks + 1;
            total_checks  = total_checks + 1;

            if (actual_empty === expected_empty) begin

                passed_checks = passed_checks + 1;

                $display(
                    "PASS | EMPTY DUT=%b EXPECTED=%b",
                    actual_empty,
                    expected_empty
                );

            end
            else begin

                failed_checks = failed_checks + 1;

                $display(
                    "FAIL | EMPTY DUT=%b EXPECTED=%b",
                    actual_empty,
                    expected_empty
                );

            end

        end

    endtask


    // ============================================================
    // OVERFLOW CHECK
    // ============================================================

    task check_overflow;

        input full_status;

        begin

            overflow_checks = overflow_checks + 1;
            total_checks    = total_checks + 1;

            if (full_status === 1'b1) begin

                passed_checks = passed_checks + 1;

                $display(
                    "PASS | OVERFLOW BLOCKED"
                );

            end
            else begin

                failed_checks = failed_checks + 1;

                $display(
                    "FAIL | OVERFLOW NOT BLOCKED"
                );

            end

        end

    endtask


    // ============================================================
    // UNDERFLOW CHECK
    // ============================================================

    task check_underflow;

        input empty_status;

        begin

            underflow_checks = underflow_checks + 1;
            total_checks     = total_checks + 1;

            if (empty_status === 1'b1) begin

                passed_checks = passed_checks + 1;

                $display(
                    "PASS | UNDERFLOW BLOCKED"
                );

            end
            else begin

                failed_checks = failed_checks + 1;

                $display(
                    "FAIL | UNDERFLOW NOT BLOCKED"
                );

            end

        end

    endtask


    // ============================================================
    // FINAL REPORT
    // ============================================================

    task report;

    begin

        $display("");
        $display("======================================");
        $display("UVM-STYLE FIFO SCOREBOARD SUMMARY");
        $display("======================================");

        $display(
            "TOTAL CHECKS     = %0d",
            total_checks
        );

        $display(
            "PASSED           = %0d",
            passed_checks
        );

        $display(
            "FAILED           = %0d",
            failed_checks
        );

        $display(
            "READ CHECKS      = %0d",
            read_checks
        );

        $display(
            "STATUS CHECKS    = %0d",
            status_checks
        );

        $display(
            "OVERFLOW CHECKS  = %0d",
            overflow_checks
        );

        $display(
            "UNDERFLOW CHECKS = %0d",
            underflow_checks
        );


        if (failed_checks == 0) begin

            $display(
                "OVERALL RESULT = PASS"
            );

        end
        else begin

            $display(
                "OVERALL RESULT = FAIL"
            );

        end


        $display("======================================");

    end

    endtask

endclass