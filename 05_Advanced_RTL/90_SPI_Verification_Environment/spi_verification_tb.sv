`timescale 1ns/1ps

module spi_verification_tb;

    localparam int CLK_DIV = 2;
    localparam int RANDOM_TESTS = 100;


    //==================================================
    // CLOCK / RESET
    //==================================================

    logic clk;
    logic rst;


    //==================================================
    // MASTER
    //==================================================

    logic       start;
    logic [7:0] master_tx;

    logic [7:0] master_rx;

    logic       master_busy;
    logic       master_done;


    //==================================================
    // SLAVE
    //==================================================

    logic [7:0] slave_tx;
    logic [7:0] slave_rx;

    logic slave_done;


    //==================================================
    // SPI BUS
    //==================================================

    logic sclk;
    logic mosi;
    logic miso;
    logic cs;


    //==================================================
    // SCOREBOARD
    //==================================================

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    integer busy_checks;
    integer cs_checks;
    integer done_checks;

    integer master_rx_checks;
    integer slave_rx_checks;


    //==================================================
    // MASTER DUT
    //==================================================

    spi_master #(
        .CLK_DIV(CLK_DIV)
    ) master_dut (

        .clk(clk),
        .rst(rst),

        .start(start),
        .tx_data(master_tx),

        .miso(miso),

        .sclk(sclk),
        .mosi(mosi),
        .cs(cs),

        .rx_data(master_rx),

        .busy(master_busy),
        .done(master_done)

    );


    //==================================================
    // SLAVE DUT
    //==================================================

    spi_slave slave_dut (

        .clk(clk),
        .rst(rst),

        .cs(cs),
        .sclk(sclk),
        .mosi(mosi),

        .miso(miso),

        .tx_data(slave_tx),

        .rx_data(slave_rx),
        .done(slave_done)

    );


    //==================================================
    // CLOCK
    //==================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    //==================================================
    // RESET
    //==================================================

    task automatic reset_spi;

        begin

            rst       = 1'b1;

            start     = 1'b0;

            master_tx = 8'h00;
            slave_tx  = 8'h00;

            repeat (4)
                @(posedge clk);

            #1;

            rst = 1'b0;

            @(posedge clk);

            #1;

            if ((cs !== 1'b1) ||
                (sclk !== 1'b0) ||
                (master_busy !== 1'b0)) begin

                $display(
                    "FAIL: SPI RESET STATE"
                );

                failed_tests =
                    failed_tests + 1;

            end

            else begin

                $display(
                    "PASS: SPI RESET STATE"
                );

            end

        end

    endtask


    //==================================================
    // SPI TRANSACTION
    //==================================================

    task automatic spi_transaction(
        input logic [7:0] tx_master,
        input logic [7:0] tx_slave
    );

        integer timeout;

        logic master_ok;
        logic slave_ok;

        begin

            total_tests =
                total_tests + 1;

            master_ok = 1'b1;
            slave_ok  = 1'b1;


            master_tx = tx_master;
            slave_tx  = tx_slave;


            //================================================
            // START
            //================================================

            start = 1'b1;

            @(posedge clk);

            #1;

            start = 1'b0;


            //================================================
            // BUSY
            //================================================

            if (master_busy !== 1'b1) begin

                $display(
                    "FAIL: BUSY NOT ASSERTED | TX=%h",
                    tx_master
                );

                failed_tests =
                    failed_tests + 1;

                master_ok = 1'b0;

            end

            else begin

                busy_checks =
                    busy_checks + 1;

            end


            //================================================
            // CS
            //================================================

            if (cs !== 1'b0) begin

                $display(
                    "FAIL: CS NOT ASSERTED"
                );

                failed_tests =
                    failed_tests + 1;

            end

            else begin

                cs_checks =
                    cs_checks + 1;

            end


            //================================================
            // WAIT FOR MASTER DONE
            //================================================

            timeout = 0;

            while (!master_done &&
                   timeout < 1000) begin

                @(posedge clk);

                #1;

                timeout =
                    timeout + 1;

            end


            //================================================
            // TIMEOUT
            //================================================

            if (timeout >= 1000) begin

                $display(
                    "FAIL: SPI TIMEOUT"
                );

                failed_tests =
                    failed_tests + 1;

                master_ok = 1'b0;
                slave_ok  = 1'b0;

            end


            //================================================
            // MASTER RECEIVE CHECK
            //================================================

            if (master_rx !== tx_slave) begin

                $display(
                    "FAIL: MASTER RX=%h EXPECTED=%h",
                    master_rx,
                    tx_slave
                );

                failed_tests =
                    failed_tests + 1;

                master_ok = 1'b0;

            end

            else begin

                master_rx_checks =
                    master_rx_checks + 1;

            end


            //================================================
            // SLAVE RECEIVE CHECK
            //================================================

            if (slave_rx !== tx_master) begin

                $display(
                    "FAIL: SLAVE RX=%h EXPECTED=%h",
                    slave_rx,
                    tx_master
                );

                failed_tests =
                    failed_tests + 1;

                slave_ok = 1'b0;

            end

            else begin

                slave_rx_checks =
                    slave_rx_checks + 1;

            end


            //================================================
            // TRANSACTION RESULT
            //================================================

            if (master_ok && slave_ok) begin

                $display(
                    "PASS: MASTER TX=%h RX=%h | SLAVE TX=%h RX=%h",
                    tx_master,
                    master_rx,
                    tx_slave,
                    slave_rx
                );

                passed_tests =
                    passed_tests + 1;

            end


            //================================================
            // DONE
            //================================================

            if (master_done === 1'b1) begin

                done_checks =
                    done_checks + 1;

            end


            //================================================
            // RETURN TO IDLE
            //================================================

            @(posedge clk);

            #1;


            if (master_busy !== 1'b0) begin

                $display(
                    "FAIL: MASTER BUSY DID NOT CLEAR"
                );

                failed_tests =
                    failed_tests + 1;

            end


            if (cs !== 1'b1) begin

                $display(
                    "FAIL: CS DID NOT DEASSERT"
                );

                failed_tests =
                    failed_tests + 1;

            end

        end

    endtask


    //==================================================
    // MAIN TEST
    //==================================================

    initial begin : main_test

        integer i;


        //================================================
        // VCD
        //================================================

        $dumpfile(
            "spi_verification.vcd"
        );

        $dumpvars(
            0,
            spi_verification_tb
        );


        //================================================
        // INITIALIZATION
        //================================================

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        busy_checks = 0;
        cs_checks   = 0;
        done_checks = 0;

        master_rx_checks = 0;
        slave_rx_checks  = 0;


        start     = 1'b0;

        master_tx = 8'h00;
        slave_tx  = 8'h00;


        //================================================
        // RESET
        //================================================

        reset_spi();


        //================================================
        // DIRECTED TESTS
        //================================================

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "TEST 1: DIRECTED SPI TRANSACTIONS"
        );

        $display(
            "=============================================="
        );


        spi_transaction(8'hA5, 8'h3C);

        spi_transaction(8'h55, 8'hF0);

        spi_transaction(8'h00, 8'hFF);

        spi_transaction(8'hFF, 8'h00);

        spi_transaction(8'hAA, 8'h55);

        spi_transaction(8'h12, 8'h34);

        spi_transaction(8'h81, 8'h18);

        spi_transaction(8'h5A, 8'hA5);


        //================================================
        // RANDOMIZED TESTS
        //================================================

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "TEST 2: RANDOMIZED SPI TRANSACTIONS"
        );

        $display(
            "=============================================="
        );


        for (i = 0; i < RANDOM_TESTS; i = i + 1) begin

            spi_transaction(
                $urandom_range(0,255),
                $urandom_range(0,255)
            );

        end


        //================================================
        // SUMMARY
        //================================================

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "SPI VERIFICATION SUMMARY"
        );

        $display(
            "=============================================="
        );


        $display(
            "TOTAL TESTS       = %0d",
            total_tests
        );

        $display(
            "PASSED TESTS      = %0d",
            passed_tests
        );

        $display(
            "FAILED TESTS      = %0d",
            failed_tests
        );

        $display(
            "BUSY CHECKS       = %0d",
            busy_checks
        );

        $display(
            "CS CHECKS         = %0d",
            cs_checks
        );

        $display(
            "DONE CHECKS       = %0d",
            done_checks
        );

        $display(
            "MASTER RX CHECKS  = %0d",
            master_rx_checks
        );

        $display(
            "SLAVE RX CHECKS   = %0d",
            slave_rx_checks
        );


        $display("");
        $display(
            "=============================================="
        );


        if (failed_tests == 0) begin

            $display(
                "OVERALL RESULT = PASS"
            );

        end

        else begin

            $display(
                "OVERALL RESULT = FAIL"
            );

        end


        $display(
            "=============================================="
        );


        $display("");
        $display(
            "SPI VERIFICATION ENVIRONMENT COMPLETE"
        );

        $display(
            "=============================================="
        );


        $finish;

    end

endmodule