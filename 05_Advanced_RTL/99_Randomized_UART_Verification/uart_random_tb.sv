`timescale 1ns/1ps

module uart_random_tb;

    localparam CLKS_PER_BIT = 4;

    logic clk;
    logic rst;

    logic [7:0] tx_data;
    logic       tx_start;

    logic tx;
    logic tx_busy;
    logic tx_done;

    logic [7:0] rx_data;
    logic       rx_valid;
    logic       rx_error;

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    integer tx_done_checks;
    integer rx_valid_checks;
    integer rx_error_checks;

    integer busy_checks;
    integer data_checks;

    integer directed_tests;
    integer randomized_tests;

    integer i;

    logic [7:0] expected_data;

    // ============================================================
    // UART TX
    // ============================================================

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) tx_dut (
        .clk      (clk),
        .rst      (rst),
        .tx_data  (tx_data),
        .tx_start (tx_start),
        .tx       (tx),
        .tx_busy  (tx_busy),
        .tx_done  (tx_done)
    );

    // ============================================================
    // UART RX
    // ============================================================

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) rx_dut (
        .clk      (clk),
        .rst      (rst),
        .rx       (tx),
        .rx_data   (rx_data),
        .rx_valid  (rx_valid),
        .rx_error  (rx_error)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    always #5 clk = ~clk;

    // ============================================================
    // CHECK RX RESULT
    // ============================================================

    task automatic check_rx_result;

        begin

            if (rx_valid && !rx_error) begin

                rx_valid_checks = rx_valid_checks + 1;
                data_checks     = data_checks + 1;

                if (rx_data !== expected_data) begin

                    $display(
                        "FAIL: DATA MISMATCH | TX=%02h RX=%02h",
                        expected_data,
                        rx_data
                    );

                    failed_tests = failed_tests + 1;

                end
                else begin

                    $display(
                        "PASS: TX=%02h RX=%02h",
                        expected_data,
                        rx_data
                    );

                    passed_tests = passed_tests + 1;

                end

            end

            else if (rx_error) begin

                rx_error_checks = rx_error_checks + 1;

                $display(
                    "FAIL: RX ERROR | DATA=%02h",
                    expected_data
                );

                failed_tests = failed_tests + 1;

            end

            else begin

                $display(
                    "FAIL: RX RESULT | DATA=%02h VALID=%0d ERROR=%0d",
                    expected_data,
                    rx_valid,
                    rx_error
                );

                failed_tests = failed_tests + 1;

            end

        end

    endtask

    // ============================================================
    // WAIT FOR RX RESULT
    // ============================================================

    task automatic wait_for_rx;

        integer timeout;
        logic result_seen;

        begin

            timeout     = 0;
            result_seen = 1'b0;

            // First check the current cycle.
            // This is important because RX VALID may occur
            // on the same cycle as TX DONE.

            #1;

            if (rx_valid || rx_error) begin

                result_seen = 1'b1;

                check_rx_result;

            end

            // If result was not present, continue waiting.
            while (!result_seen && timeout < 100) begin

                @(posedge clk);
                #1;

                if (rx_valid || rx_error) begin

                    result_seen = 1'b1;

                    check_rx_result;

                end

                timeout = timeout + 1;

            end

            if (!result_seen) begin

                $display(
                    "FAIL: RX TIMEOUT | EXPECTED=%02h",
                    expected_data
                );

                failed_tests = failed_tests + 1;

            end

        end

    endtask

    // ============================================================
    // SEND ONE BYTE
    // ============================================================

    task automatic send_byte(
        input logic [7:0] data
    );

        integer busy_timeout;
        integer done_timeout;

        begin

            expected_data = data;

            // ----------------------------------------------------
            // Wait until TX is idle
            // ----------------------------------------------------

            busy_timeout = 0;

            while (tx_busy && busy_timeout < 100) begin

                @(posedge clk);
                #1;

                busy_timeout = busy_timeout + 1;

            end

            // ----------------------------------------------------
            // Start transmission
            // ----------------------------------------------------

            @(posedge clk);
            #1;

            tx_data  = data;
            tx_start = 1'b1;

            @(posedge clk);
            #1;

            tx_start = 1'b0;

            // ----------------------------------------------------
            // TX BUSY check
            // ----------------------------------------------------

            busy_checks = busy_checks + 1;

            if (!tx_busy) begin

                $display(
                    "FAIL: TX BUSY NOT ASSERTED | DATA=%02h",
                    data
                );

                failed_tests = failed_tests + 1;

            end

            // ----------------------------------------------------
            // Wait for TX DONE
            // ----------------------------------------------------

            done_timeout = 0;

            while (!tx_done && done_timeout < 100) begin

                @(posedge clk);
                #1;

                done_timeout = done_timeout + 1;

            end

            if (tx_done) begin

                tx_done_checks = tx_done_checks + 1;

            end
            else begin

                $display(
                    "FAIL: TX DONE TIMEOUT | DATA=%02h",
                    data
                );

                failed_tests = failed_tests + 1;

            end

            // ----------------------------------------------------
            // IMPORTANT FIX
            //
            // RX VALID may occur in the SAME cycle as TX DONE.
            //
            // Therefore check RX immediately before waiting
            // for another clock.
            // ----------------------------------------------------

            wait_for_rx;

            total_tests = total_tests + 1;

        end

    endtask

    // ============================================================
    // RESET
    // ============================================================

    task automatic reset_uart;

        begin

            rst      = 1'b1;
            tx_start = 1'b0;
            tx_data  = 8'h00;

            repeat (3)
                @(posedge clk);

            #1;

            rst = 1'b0;

            $display("PASS: UART RESET");

        end

    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        $dumpfile("uart_random.vcd");
        $dumpvars(0, uart_random_tb);

        clk = 1'b0;
        rst = 1'b0;

        tx_data  = 8'h00;
        tx_start = 1'b0;

        total_tests = 0;
        passed_tests = 0;
        failed_tests = 0;

        tx_done_checks  = 0;
        rx_valid_checks = 0;
        rx_error_checks = 0;

        busy_checks = 0;
        data_checks = 0;

        directed_tests   = 0;
        randomized_tests = 0;

        expected_data = 8'h00;

        $display("==============================================");
        $display("RANDOMIZED UART VERIFICATION");
        $display("==============================================");

        // ========================================================
        // RESET
        // ========================================================

        reset_uart;

        // ========================================================
        // DIRECTED TESTS
        // ========================================================

        $display("");
        $display("DIRECTED UART TESTS");
        $display("----------------------------------------------");

        send_byte(8'h00);
        directed_tests = directed_tests + 1;

        send_byte(8'hFF);
        directed_tests = directed_tests + 1;

        send_byte(8'hAA);
        directed_tests = directed_tests + 1;

        send_byte(8'h55);
        directed_tests = directed_tests + 1;

        send_byte(8'h01);
        directed_tests = directed_tests + 1;

        send_byte(8'h80);
        directed_tests = directed_tests + 1;

        send_byte(8'h7F);
        directed_tests = directed_tests + 1;

        send_byte(8'h3C);
        directed_tests = directed_tests + 1;

        send_byte(8'hC3);
        directed_tests = directed_tests + 1;

        send_byte(8'hA5);
        directed_tests = directed_tests + 1;

        // ========================================================
        // RANDOMIZED TESTS
        // ========================================================

        $display("");
        $display("1000 RANDOMIZED UART TESTS");
        $display("----------------------------------------------");

        for (i = 0; i < 1000; i = i + 1) begin

            send_byte(
                $urandom_range(0,255)
            );

            randomized_tests =
                randomized_tests + 1;

        end

        // ========================================================
        // SUMMARY
        // ========================================================

        $display("");
        $display("==============================================");
        $display("RANDOMIZED UART VERIFICATION SUMMARY");
        $display("==============================================");

        $display(
            "TOTAL TESTS       = %0d",
            total_tests
        );

        $display(
            "DIRECTED TESTS    = %0d",
            directed_tests
        );

        $display(
            "RANDOMIZED TESTS  = %0d",
            randomized_tests
        );

        $display("");

        $display(
            "PASSED TESTS      = %0d",
            passed_tests
        );

        $display(
            "FAILED TESTS      = %0d",
            failed_tests
        );

        $display("");

        $display(
            "TX DONE CHECKS    = %0d",
            tx_done_checks
        );

        $display(
            "RX VALID CHECKS   = %0d",
            rx_valid_checks
        );

        $display(
            "RX ERROR CHECKS   = %0d",
            rx_error_checks
        );

        $display(
            "BUSY CHECKS       = %0d",
            busy_checks
        );

        $display(
            "DATA CHECKS       = %0d",
            data_checks
        );

        $display("----------------------------------------------");

        if (failed_tests == 0) begin

            $display("OVERALL RESULT = PASS");
            $display(
                "RANDOMIZED UART VERIFICATION COMPLETE"
            );

        end
        else begin

            $display("OVERALL RESULT = FAIL");

        end

        $display("==============================================");

        $finish;

    end

endmodule