`timescale 1ns/1ps

module spi_tb;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    logic clk;
    logic rst;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // SPI MASTER SIGNALS
    // ============================================================

    logic       start;
    logic [7:0] master_tx;
    logic [7:0] master_rx;
    logic       master_busy;
    logic       master_done;

    logic       cs;
    logic       sclk;
    logic       mosi;
    logic       miso;

    // ============================================================
    // SPI SLAVE SIGNALS
    // ============================================================

    logic [7:0] slave_tx;
    logic [7:0] slave_rx;
    logic       slave_rx_valid;

    // ============================================================
    // DUT - SPI MASTER
    // ============================================================

    spi_master master_dut (
        .clk       (clk),
        .rst       (rst),
        .start     (start),
        .tx_data   (master_tx),
        .rx_data   (master_rx),
        .busy      (master_busy),
        .done      (master_done),
        .cs        (cs),
        .sclk      (sclk),
        .mosi      (mosi),
        .miso      (miso)
    );

    // ============================================================
    // DUT - SPI SLAVE
    // ============================================================

    spi_slave slave_dut (
    .cs        (cs),
    .sclk      (sclk),
    .mosi      (mosi),
    .miso      (miso),
    .tx_data   (slave_tx),
    .rx_data    (slave_rx),
    .rx_valid  (slave_rx_valid)
    );

    // ============================================================
    // LOOPBACK CONNECTION
    // ============================================================

    // Master MOSI -> Slave MOSI input
    // Slave MISO -> Master MISO input

    // ============================================================
    // VERIFICATION COUNTERS
    // ============================================================

    integer directed_tests;
    integer randomized_tests;
    integer total_tests;

    integer passed_checks;
    integer failed_checks;

    integer busy_checks;
    integer done_checks;
    integer slave_rx_checks;
    integer master_rx_checks;
    integer cs_checks;
    integer clock_checks;

    integer transaction_count;

    // ============================================================
    // VCD
    // ============================================================

    initial begin
        $dumpfile("uvm_spi.vcd");
        $dumpvars(0, spi_tb);
    end

    // ============================================================
    // SCOREBOARD TASK
    // ============================================================

    task automatic pass_check(input [8*60-1:0] message);
        begin
            $display("[SCOREBOARD] PASS %s", message);
            passed_checks = passed_checks + 1;
        end
    endtask

    task automatic fail_check(input [8*60-1:0] message);
        begin
            $display("[SCOREBOARD] FAIL %s", message);
            failed_checks = failed_checks + 1;
        end
    endtask

    // ============================================================
    // SPI TRANSACTION
    // ============================================================

    task automatic run_spi_transaction(
        input [7:0] tx_master,
        input [7:0] tx_slave
    );

        integer timeout;
        begin

            transaction_count = transaction_count + 1;

            $display("");
            $display("================================================");
            $display("[SEQUENCER] SPI TRANSACTION #%0d",
                     transaction_count);
            $display("[SEQUENCER] MASTER TX = %02h", tx_master);
            $display("[SEQUENCER] SLAVE TX  = %02h", tx_slave);
            $display("================================================");

            // ----------------------------------------------------
            // Load transaction
            // ----------------------------------------------------

            master_tx = tx_master;
            slave_tx  = tx_slave;

            // ----------------------------------------------------
            // Make sure SPI is idle before starting
            // ----------------------------------------------------

            start = 1'b0;

            @(posedge clk);
            #1;

            // ----------------------------------------------------
            // BUSY / CS / SCLK initial checks
            //
            // IMPORTANT:
            // #1 is intentionally used after the clock edge.
            // This avoids checking signals before NBA updates.
            // ----------------------------------------------------

            start = 1'b1;

            @(posedge clk);
            #1;

            // BUSY
            if (master_busy === 1'b1) begin
                pass_check("MASTER BUSY ASSERTED");
                busy_checks = busy_checks + 1;
            end
            else begin
                fail_check("MASTER BUSY ASSERTED");
            end

            // CS
            if (cs === 1'b0) begin
                pass_check("CS ASSERTED LOW");
                cs_checks = cs_checks + 1;
            end
            else begin
                fail_check("CS ASSERTED LOW");
            end

            // SCLK
            //
            // The #1 delay is the critical race-condition fix.
            // The original test checked SCLK in the same simulation
            // timestep as the DUT NBA update.
            //
            if (sclk === 1'b0) begin
                pass_check("SCLK STARTS LOW");
                clock_checks = clock_checks + 1;
            end
            else begin
                fail_check("SCLK STARTS LOW");
            end

            // Remove start after it has been sampled
            start = 1'b0;

            // ----------------------------------------------------
            // Wait for transaction to complete
            // ----------------------------------------------------

            timeout = 0;

            while (master_done !== 1'b1 && timeout < 1000) begin
                @(posedge clk);
                #1;
                timeout = timeout + 1;
            end

            // ----------------------------------------------------
            // DONE CHECK
            // ----------------------------------------------------

            if (master_done === 1'b1) begin
                pass_check("MASTER DONE");
                done_checks = done_checks + 1;
            end
            else begin
                fail_check("MASTER DONE");
            end

            // ----------------------------------------------------
            // SLAVE RX CHECK
            // ----------------------------------------------------

            if (slave_rx === tx_master) begin
                pass_check("SLAVE RX MATCHES MASTER TX");
                slave_rx_checks = slave_rx_checks + 1;
            end
            else begin
                $display(
                    "[SCOREBOARD] FAIL       SLAVE RX MATCHES MASTER TX Expected=%02h Received=%02h",
                    tx_master,
                    slave_rx
                );
                failed_checks = failed_checks + 1;
            end

            // ----------------------------------------------------
            // MASTER RX CHECK
            // ----------------------------------------------------

            if (master_rx === tx_slave) begin
                pass_check("MASTER RX MATCHES SLAVE TX");
                master_rx_checks = master_rx_checks + 1;
            end
            else begin
                $display(
                    "[SCOREBOARD] FAIL       MASTER RX MATCHES SLAVE TX Expected=%02h Received=%02h",
                    tx_slave,
                    master_rx
                );
                failed_checks = failed_checks + 1;
            end

            // ----------------------------------------------------
            // SLAVE RX VALID
            // ----------------------------------------------------

            if (slave_rx_valid === 1'b1) begin
                pass_check("SLAVE RX VALID");
            end
            else begin
                fail_check("SLAVE RX VALID");
            end

            // ----------------------------------------------------
            // Wait one more clock so BUSY / CS / SCLK return
            // completely to idle.
            // ----------------------------------------------------

            @(posedge clk);
            #1;

            // ----------------------------------------------------
            // BUSY DEASSERT
            // ----------------------------------------------------

            if (master_busy === 1'b0) begin
                pass_check("MASTER BUSY DEASSERTED");
                busy_checks = busy_checks + 1;
            end
            else begin
                fail_check("MASTER BUSY DEASSERTED");
            end

            // ----------------------------------------------------
            // CS DEASSERT
            // ----------------------------------------------------

            if (cs === 1'b1) begin
                pass_check("CS DEASSERTED HIGH");
                cs_checks = cs_checks + 1;
            end
            else begin
                fail_check("CS DEASSERTED HIGH");
            end

            // ----------------------------------------------------
            // SCLK IDLE
            // ----------------------------------------------------

            if (sclk === 1'b0) begin
                pass_check("SCLK RETURNS TO IDLE");
                clock_checks = clock_checks + 1;
            end
            else begin
                fail_check("SCLK RETURNS TO IDLE");
            end

            // ----------------------------------------------------
            // MONITOR OUTPUT
            // ----------------------------------------------------

            $display(
                "[MONITOR] MASTER_TX=%02h SLAVE_RX=%02h",
                tx_master,
                slave_rx
            );

            $display(
                "[MONITOR] SLAVE_TX=%02h MASTER_RX=%02h",
                tx_slave,
                master_rx
            );

        end

    endtask

    // ============================================================
    // INITIAL TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // Initialize
        // --------------------------------------------------------

        rst = 1'b1;

        start     = 1'b0;
        master_tx = 8'h00;
        slave_tx  = 8'h00;

        directed_tests   = 0;
        randomized_tests = 0;
        total_tests      = 0;

        passed_checks = 0;
        failed_checks = 0;

        busy_checks      = 0;
        done_checks      = 0;
        slave_rx_checks  = 0;
        master_rx_checks = 0;
        cs_checks        = 0;
        clock_checks     = 0;

        transaction_count = 0;

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        repeat (4) begin
            @(posedge clk);
            #1;
        end

        rst = 1'b0;

        @(posedge clk);
        #1;

        // --------------------------------------------------------
        // TEST START
        // --------------------------------------------------------

        $display("");
        $display("================================================");
        $display("       UVM-STYLE SPI TEST START");
        $display("================================================");

        $display("[ENV] SPI environment built");
        $display("[AGENT] SPI agent started");
        $display("[DRIVER] SPI driver ready");
        $display("[MONITOR] SPI monitor ready");
        $display("[SCOREBOARD] SPI scoreboard ready");

        // ========================================================
        // DIRECTED TESTS
        // ========================================================

        $display("");
        $display("------------- DIRECTED TESTS ------------------");

        run_spi_transaction(8'h00, 8'h00);
        directed_tests = directed_tests + 1;

        run_spi_transaction(8'hFF, 8'hFF);
        directed_tests = directed_tests + 1;

        run_spi_transaction(8'hA5, 8'h3C);
        directed_tests = directed_tests + 1;

        run_spi_transaction(8'h55, 8'hAA);
        directed_tests = directed_tests + 1;

        run_spi_transaction(8'h12, 8'h7E);
        directed_tests = directed_tests + 1;

        run_spi_transaction(8'h80, 8'h01);
        directed_tests = directed_tests + 1;

        run_spi_transaction(8'hF0, 8'h0F);
        directed_tests = directed_tests + 1;

        run_spi_transaction(8'h5A, 8'hA5);
        directed_tests = directed_tests + 1;

        // ========================================================
        // RANDOMIZED TESTS
        // ========================================================

        $display("");
        $display("------------- RANDOMIZED TESTS ----------------");

        repeat (100) begin

            run_spi_transaction(
                $random,
                $random
            );

            randomized_tests = randomized_tests + 1;

        end

        // ========================================================
        // FINAL COUNTS
        // ========================================================

        total_tests = directed_tests + randomized_tests;

        // --------------------------------------------------------
        // FINAL VERIFICATION
        // --------------------------------------------------------

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display("DIRECTED TESTS       = %0d",
                 directed_tests);

        $display("RANDOMIZED TESTS     = %0d",
                 randomized_tests);

        $display("TOTAL TESTS          = %0d",
                 total_tests);

        $display("PASSED CHECKS        = %0d",
                 passed_checks);

        $display("FAILED CHECKS        = %0d",
                 failed_checks);

        $display("BUSY CHECKS          = %0d",
                 busy_checks);

        $display("DONE CHECKS          = %0d",
                 done_checks);

        $display("SLAVE RX CHECKS      = %0d",
                 slave_rx_checks);

        $display("MASTER RX CHECKS     = %0d",
                 master_rx_checks);

        $display("CS CHECKS            = %0d",
                 cs_checks);

        $display("CLOCK CHECKS         = %0d",
                 clock_checks);

        $display("");

        if (failed_checks == 0) begin

            $display("OVERALL RESULT = PASS");

        end
        else begin

            $display("OVERALL RESULT = FAIL");

        end

        $display("================================================");

        #20;

        $finish;

    end

endmodule