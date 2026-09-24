`timescale 1ns/1ps

module apb_random_tb;

    parameter ADDR_WIDTH = 8;
    parameter DATA_WIDTH = 32;

    logic clk;
    logic rst;

    logic start;
    logic write_en;

    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wdata;

    logic [DATA_WIDTH-1:0] rdata;
    logic done;
    logic busy;

    logic psel;
    logic penable;
    logic pwrite;

    logic [ADDR_WIDTH-1:0] paddr;
    logic [DATA_WIDTH-1:0] pwdata;

    logic [DATA_WIDTH-1:0] prdata;
    logic pready;
    logic pslverr;

    logic [DATA_WIDTH-1:0] expected_mem [0:255];

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    integer read_tests;
    integer write_tests;

    integer success_tests;
    integer error_tests;

    integer busy_checks;
    integer done_checks;
    integer data_checks;

    integer wait_tests;
    integer wait_cycles;

    integer i;

    always #5 clk = ~clk;


    /* APB MASTER */

    apb_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) master (
        .clk(clk),
        .rst(rst),

        .start(start),
        .write_en(write_en),
        .addr(addr),
        .wdata(wdata),

        .rdata(rdata),
        .done(done),
        .busy(busy),

        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),

        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr)
    );


    /* APB SLAVE */

    apb_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) slave (
        .clk(clk),
        .rst(rst),

        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),

        .paddr(paddr),
        .pwdata(pwdata),

        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr)
    );


    /* VCD */

    initial begin
        $dumpfile("apb_random.vcd");
        $dumpvars(0, apb_random_tb);
    end


    /* RESET */

    task reset_dut;

        begin

            rst      = 1'b1;
            start    = 1'b0;
            write_en = 1'b0;
            addr     = '0;
            wdata    = '0;

            repeat (4)
                @(posedge clk);

            rst = 1'b0;

            @(posedge clk);

        end

    endtask


    /* TRANSACTION */

    task automatic run_transaction(
        input logic                  is_write,
        input logic [ADDR_WIDTH-1:0] test_addr,
        input logic [DATA_WIDTH-1:0] test_data
    );

        logic expected_error;
        logic [DATA_WIDTH-1:0] expected_data;

        begin

            total_tests = total_tests + 1;

            expected_error =
                (test_addr[1:0] == 2'b11);


            if (is_write)
                write_tests = write_tests + 1;
            else
                read_tests = read_tests + 1;


            if (expected_error)
                error_tests = error_tests + 1;
            else
                success_tests = success_tests + 1;


            /* START TRANSACTION */

            @(posedge clk);

            addr     <= test_addr;
            wdata    <= test_data;
            write_en <= is_write;
            start    <= 1'b1;

            @(posedge clk);

            start <= 1'b0;


            /*
             * Allow NBA updates from the master
             * to become visible.
             */
            #1;


            /* BUSY CHECK */

            if (busy) begin

                busy_checks = busy_checks + 1;

            end

            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "FAIL: BUSY not asserted | ADDR=%02h",
                    test_addr
                );

            end


            /*
             * Monitor APB ACCESS phase.
             * Count wait cycles.
             */
            wait_cycles = 0;

            while (!done) begin

                @(posedge clk);

                #1;

                if (psel && penable && !pready)
                    wait_cycles = wait_cycles + 1;

            end


            done_checks = done_checks + 1;


            if (wait_cycles > 0)
                wait_tests = wait_tests + 1;


            /* SCOREBOARD */

            if (expected_error) begin

                if (pslverr) begin

                    passed_tests = passed_tests + 1;

                    $display(
                        "PASS: ERROR | %s | ADDR=%02h | WAIT=%0d",
                        is_write ? "WRITE" : "READ",
                        test_addr,
                        wait_cycles
                    );

                end

                else begin

                    failed_tests = failed_tests + 1;

                    $display(
                        "FAIL: ERROR RESPONSE | ADDR=%02h",
                        test_addr
                    );

                end

            end

            else if (is_write) begin

                expected_mem[test_addr] = test_data;

                passed_tests = passed_tests + 1;

                $display(
                    "PASS: WRITE | ADDR=%02h DATA=%08h WAIT=%0d",
                    test_addr,
                    test_data,
                    wait_cycles
                );

            end

            else begin

                expected_data = expected_mem[test_addr];

                data_checks = data_checks + 1;

                if (rdata === expected_data) begin

                    passed_tests = passed_tests + 1;

                    $display(
                        "PASS: READ | ADDR=%02h DATA=%08h WAIT=%0d",
                        test_addr,
                        rdata,
                        wait_cycles
                    );

                end

                else begin

                    failed_tests = failed_tests + 1;

                    $display(
                        "FAIL: READ | ADDR=%02h EXPECTED=%08h GOT=%08h",
                        test_addr,
                        expected_data,
                        rdata
                    );

                end

            end


            @(posedge clk);

        end

    endtask


    /* MAIN TEST */

    initial begin

        clk = 1'b0;

        rst = 1'b0;

        start    = 1'b0;
        write_en = 1'b0;

        addr  = '0;
        wdata = '0;

        total_tests = 0;
        passed_tests = 0;
        failed_tests = 0;

        read_tests  = 0;
        write_tests = 0;

        success_tests = 0;
        error_tests   = 0;

        busy_checks = 0;
        done_checks = 0;
        data_checks = 0;

        wait_tests  = 0;
        wait_cycles = 0;


        for (i = 0; i < 256; i = i + 1)
            expected_mem[i] = '0;


        reset_dut;


        $display("");
        $display("==============================================");
        $display("RANDOMIZED APB VERIFICATION");
        $display("==============================================");
        $display("");


        /* DIRECTED TESTS */

        run_transaction(
            1'b1,
            8'h10,
            32'h12345678
        );

        run_transaction(
            1'b0,
            8'h10,
            32'h00000000
        );


        run_transaction(
            1'b1,
            8'h20,
            32'hA5A5A5A5
        );

        run_transaction(
            1'b0,
            8'h20,
            32'h00000000
        );


        run_transaction(
            1'b1,
            8'h30,
            32'hDEADBEEF
        );

        run_transaction(
            1'b0,
            8'h30,
            32'h00000000
        );


        /* ERROR TESTS */

        run_transaction(
            1'b1,
            8'h13,
            32'h11111111
        );

        run_transaction(
            1'b0,
            8'h13,
            32'h00000000
        );


        run_transaction(
            1'b1,
            8'h23,
            32'h22222222
        );

        run_transaction(
            1'b0,
            8'h23,
            32'h00000000
        );


        /* 500 RANDOMIZED TRANSACTIONS */

        for (i = 0; i < 500; i = i + 1) begin

            run_transaction(
                $urandom_range(0,1),
                $urandom_range(0,255),
                $urandom
            );

        end


        /* SUMMARY */

        $display("");
        $display("==============================================");
        $display("RANDOMIZED APB VERIFICATION SUMMARY");
        $display("==============================================");

        $display(
            "TOTAL TESTS       = %0d",
            total_tests
        );

        $display(
            "READ TESTS        = %0d",
            read_tests
        );

        $display(
            "WRITE TESTS       = %0d",
            write_tests
        );

        $display(
            "SUCCESS TESTS     = %0d",
            success_tests
        );

        $display(
            "ERROR TESTS       = %0d",
            error_tests
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
            "BUSY CHECKS       = %0d",
            busy_checks
        );

        $display(
            "DONE CHECKS       = %0d",
            done_checks
        );

        $display(
            "DATA CHECKS       = %0d",
            data_checks
        );

        $display(
            "WAIT STATE TESTS  = %0d",
            wait_tests
        );

        $display("----------------------------------------------");

        if (failed_tests == 0)
            $display("OVERALL RESULT = PASS");
        else
            $display("OVERALL RESULT = FAIL");

        $display(
            "RANDOMIZED APB VERIFICATION COMPLETE"
        );

        $display(
            "=============================================="
        );


        $finish;

    end

endmodule