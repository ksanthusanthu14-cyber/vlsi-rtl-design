class uart_scoreboard;

    integer total_checks;
    integer passed_checks;
    integer failed_checks;

    integer tx_done_checks;
    integer rx_valid_checks;
    integer data_checks;
    integer busy_checks;
    integer error_checks;

    function new();

        total_checks    = 0;
        passed_checks   = 0;
        failed_checks   = 0;

        tx_done_checks  = 0;
        rx_valid_checks = 0;
        data_checks     = 0;
        busy_checks     = 0;
        error_checks    = 0;

    endfunction


    task check_data(
        input [7:0] expected,
        input [7:0] received
    );

        total_checks = total_checks + 1;
        data_checks  = data_checks + 1;

        if (expected == received) begin

            passed_checks = passed_checks + 1;

            $display(
                "[SCOREBOARD] PASS DATA Expected=%02h Received=%02h",
                expected,
                received
            );

        end
        else begin

            failed_checks = failed_checks + 1;

            $display(
                "[SCOREBOARD] FAIL DATA Expected=%02h Received=%02h",
                expected,
                received
            );

        end

    endtask


    task check_rx_valid(input rx_valid);

        total_checks    = total_checks + 1;
        rx_valid_checks = rx_valid_checks + 1;

        if (rx_valid) begin
            passed_checks = passed_checks + 1;
            $display("[SCOREBOARD] PASS RX_VALID");
        end
        else begin
            failed_checks = failed_checks + 1;
            $display("[SCOREBOARD] FAIL RX_VALID");
        end

    endtask


    task check_tx_done(input tx_done);

        total_checks   = total_checks + 1;
        tx_done_checks = tx_done_checks + 1;

        if (tx_done) begin
            passed_checks = passed_checks + 1;
            $display("[SCOREBOARD] PASS TX_DONE");
        end
        else begin
            failed_checks = failed_checks + 1;
            $display("[SCOREBOARD] FAIL TX_DONE");
        end

    endtask


    task check_busy(input busy_seen);

        total_checks = total_checks + 1;
        busy_checks  = busy_checks + 1;

        if (busy_seen) begin
            passed_checks = passed_checks + 1;
            $display("[SCOREBOARD] PASS BUSY");
        end
        else begin
            failed_checks = failed_checks + 1;
            $display("[SCOREBOARD] FAIL BUSY");
        end

    endtask


    task check_error(input rx_error);

        total_checks = total_checks + 1;
        error_checks = error_checks + 1;

        if (!rx_error) begin
            passed_checks = passed_checks + 1;
            $display("[SCOREBOARD] PASS RX_ERROR=0");
        end
        else begin
            failed_checks = failed_checks + 1;
            $display("[SCOREBOARD] FAIL RX_ERROR=1");
        end

    endtask


    task report;

        $display("");
        $display("================================================");
        $display("             UART SCOREBOARD");
        $display("================================================");

        $display("TOTAL CHECKS       = %0d", total_checks);
        $display("PASSED             = %0d", passed_checks);
        $display("FAILED             = %0d", failed_checks);
        $display("TX DONE CHECKS     = %0d", tx_done_checks);
        $display("RX VALID CHECKS    = %0d", rx_valid_checks);
        $display("DATA CHECKS        = %0d", data_checks);
        $display("BUSY CHECKS        = %0d", busy_checks);
        $display("RX ERROR CHECKS    = %0d", error_checks);

        if (failed_checks == 0)
            $display("SCOREBOARD RESULT = PASS");
        else
            $display("SCOREBOARD RESULT = FAIL");

        $display("================================================");

    endtask

endclass