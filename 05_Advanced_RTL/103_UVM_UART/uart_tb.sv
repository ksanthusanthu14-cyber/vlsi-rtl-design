`timescale 1ns/1ps

module uart_tb;

    parameter CLK_PER_BIT = 4;

    logic clk;
    logic rst;

    logic       tx_start;
    logic [7:0] tx_data;
    logic       tx;

    logic       tx_busy;
    logic       tx_done;

    logic       rx;
    logic [7:0] rx_data;
    logic       rx_valid;
    logic       rx_error;

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    integer tx_done_checks;
    integer rx_valid_checks;
    integer data_checks;
    integer busy_checks;
    integer error_checks;

    integer busy_seen;

    reg [7:0] test_data;


    // ============================================================
    // DUT
    // ============================================================

    uart #(
        .CLK_PER_BIT(CLK_PER_BIT)
    ) dut (
        .clk(clk),
        .rst(rst),

        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),

        .tx_busy(tx_busy),
        .tx_done(tx_done),

        .rx(rx),
        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_error(rx_error)
    );


    // ============================================================
    // UART LOOPBACK
    // ============================================================

    assign rx = tx;


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ============================================================
    // VCD
    // ============================================================

    initial begin
        $dumpfile("uvm_uart.vcd");
        $dumpvars(0, uart_tb);
    end


    // ============================================================
    // SCOREBOARD CHECK TASKS
    // ============================================================

    task check_busy;

        begin

            busy_checks = busy_checks + 1;
            total_tests = total_tests + 1;

            if (busy_seen) begin

                passed_tests = passed_tests + 1;

                $display("[SCOREBOARD] PASS BUSY");

            end
            else begin

                failed_tests = failed_tests + 1;

                $display("[SCOREBOARD] FAIL BUSY");

            end

        end

    endtask


    task check_tx_done;

        begin

            tx_done_checks = tx_done_checks + 1;
            total_tests = total_tests + 1;

            if (tx_done) begin

                passed_tests = passed_tests + 1;

                $display("[SCOREBOARD] PASS TX_DONE");

            end
            else begin

                failed_tests = failed_tests + 1;

                $display("[SCOREBOARD] FAIL TX_DONE");

            end

        end

    endtask


    task check_rx_valid;

        begin

            rx_valid_checks = rx_valid_checks + 1;
            total_tests = total_tests + 1;

            if (rx_valid) begin

                passed_tests = passed_tests + 1;

                $display("[SCOREBOARD] PASS RX_VALID");

            end
            else begin

                failed_tests = failed_tests + 1;

                $display("[SCOREBOARD] FAIL RX_VALID");

            end

        end

    endtask


    task check_data;

        input [7:0] expected;
        input [7:0] received;

        begin

            data_checks = data_checks + 1;
            total_tests = total_tests + 1;

            if (expected == received) begin

                passed_tests = passed_tests + 1;

                $display(
                    "[SCOREBOARD] PASS DATA Expected=%02h Received=%02h",
                    expected,
                    received
                );

            end
            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "[SCOREBOARD] FAIL DATA Expected=%02h Received=%02h",
                    expected,
                    received
                );

            end

        end

    endtask


    task check_error;

        begin

            error_checks = error_checks + 1;
            total_tests = total_tests + 1;

            if (!rx_error) begin

                passed_tests = passed_tests + 1;

                $display("[SCOREBOARD] PASS RX_ERROR=0");

            end
            else begin

                failed_tests = failed_tests + 1;

                $display("[SCOREBOARD] FAIL RX_ERROR=1");

            end

        end

    endtask


    // ============================================================
    // ONE UART TRANSACTION
    // ============================================================

    task run_transaction;

        input [7:0] data;

        begin

            $display("");
            $display("----------------------------------------------");
            $display("[SEQUENCER] Generated DATA = %02h", data);
            $display("----------------------------------------------");


            // ----------------------------------------------------
            // DRIVER
            // ----------------------------------------------------

            tx_data  = data;
            tx_start = 1'b1;

            @(posedge clk);

            #1;

            tx_start = 1'b0;

            $display(
                "[DRIVER] Transmitting DATA = %02h",
                data
            );


            // ----------------------------------------------------
            // MONITOR BUSY
            // ----------------------------------------------------

            busy_seen = 0;

            repeat (3) begin

                @(posedge clk);

                #1;

                if (tx_busy)
                    busy_seen = 1;

            end

            check_busy();


            // ----------------------------------------------------
            // WAIT FOR TX DONE
            // ----------------------------------------------------

            wait (tx_done == 1'b1);

            #1;

            $display("[MONITOR] TX DONE detected");

            check_tx_done();


            // ----------------------------------------------------
            // WAIT FOR RX VALID
            // ----------------------------------------------------

            wait (rx_valid == 1'b1);

            #1;

            $display(
                "[MONITOR] RX DATA = %02h ERROR = %b",
                rx_data,
                rx_error
            );

            check_rx_valid();

            check_data(
                data,
                rx_data
            );

            check_error();


            $display(
                "[TEST] COMPLETE DATA = %02h",
                data
            );


            @(posedge clk);

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        rst      = 1'b1;
        tx_start = 1'b0;
        tx_data  = 8'h00;

        total_tests    = 0;
        passed_tests   = 0;
        failed_tests   = 0;

        tx_done_checks  = 0;
        rx_valid_checks = 0;
        data_checks     = 0;
        busy_checks     = 0;
        error_checks    = 0;

        $display("");
        $display("================================================");
        $display("       UVM-STYLE UART TEST START");
        $display("================================================");


        // --------------------------------------------------------
        // RESET
        // --------------------------------------------------------

        repeat (5)
            @(posedge clk);

        rst = 1'b0;

        @(posedge clk);


        $display("");
        $display("[ENV] UART environment built");
        $display("[AGENT] UART agent started");


        // ========================================================
        // DIRECTED TESTS
        // ========================================================

        $display("");
        $display("--------------- DIRECTED TESTS ----------------");


        run_transaction(8'h00);
        run_transaction(8'hFF);
        run_transaction(8'hA5);
        run_transaction(8'h5A);
        run_transaction(8'h3C);
        run_transaction(8'hC3);
        run_transaction(8'h55);
        run_transaction(8'hAA);
        run_transaction(8'h12);
        run_transaction(8'h81);


        // ========================================================
        // RANDOMIZED TESTS
        // ========================================================

        $display("");
        $display("------------- RANDOMIZED TESTS ----------------");


        repeat (100) begin

            test_data = $random;

            run_transaction(test_data);

        end


        // ========================================================
        // FINAL REPORT
        // ========================================================

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display("DIRECTED TESTS       = 10");
        $display("RANDOMIZED TESTS     = 100");
        $display("TOTAL TESTS          = 110");

        $display(
            "PASSED CHECKS        = %0d",
            passed_tests
        );

        $display(
            "FAILED CHECKS        = %0d",
            failed_tests
        );

        $display(
            "TX DONE CHECKS       = %0d",
            tx_done_checks
        );

        $display(
            "RX VALID CHECKS      = %0d",
            rx_valid_checks
        );

        $display(
            "DATA CHECKS          = %0d",
            data_checks
        );

        $display(
            "BUSY CHECKS          = %0d",
            busy_checks
        );

        $display(
            "RX ERROR CHECKS      = %0d",
            error_checks
        );


        if (failed_tests == 0) begin

            $display("");
            $display("OVERALL RESULT = PASS");
            $display("UVM-STYLE UART VERIFICATION COMPLETE");

        end
        else begin

            $display("");
            $display("OVERALL RESULT = FAIL");

        end


        $display("================================================");


        #20;

        $finish;

    end

endmodule