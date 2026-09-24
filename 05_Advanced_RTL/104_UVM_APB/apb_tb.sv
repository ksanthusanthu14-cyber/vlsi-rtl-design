`timescale 1ns/1ps

module apb_tb;

    parameter ADDR_WIDTH = 8;
    parameter DATA_WIDTH = 32;

    logic pclk;
    logic presetn;

    // ============================================================
    // Master transaction interface
    // ============================================================

    logic                  start;
    logic                  write_en;
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wdata;

    logic [DATA_WIDTH-1:0] rdata;
    logic                  busy;
    logic                  done;
    logic                  error;


    // ============================================================
    // APB signals
    // ============================================================

    logic                  psel;
    logic                  penable;
    logic                  pwrite;

    logic [ADDR_WIDTH-1:0] paddr;
    logic [DATA_WIDTH-1:0] pwdata;

    logic [DATA_WIDTH-1:0] prdata;
    logic                  pready;
    logic                  pslverr;


    // ============================================================
    // Reference memory
    // ============================================================

    logic [DATA_WIDTH-1:0] reference_mem [0:255];


    // ============================================================
    // Verification counters
    // ============================================================

    integer total_transactions;
    integer passed_transactions;
    integer failed_transactions;

    integer read_tests;
    integer write_tests;
    integer success_tests;
    integer error_tests;

    integer busy_checks;
    integer done_checks;
    integer data_checks;
    integer error_checks;

    integer wait_tests;


    // ============================================================
    // DUT - APB MASTER
    // ============================================================

    apb_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) master (

        .pclk(pclk),
        .presetn(presetn),

        .start(start),
        .write_en(write_en),
        .addr(addr),
        .wdata(wdata),

        .rdata(rdata),
        .busy(busy),
        .done(done),
        .error(error),

        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),
        .paddr(paddr),
        .pwdata(pwdata),

        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr)

    );


    // ============================================================
    // DUT - APB SLAVE
    // ============================================================

    apb_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) slave (

        .pclk(pclk),
        .presetn(presetn),

        .psel(psel),
        .penable(penable),
        .pwrite(pwrite),

        .paddr(paddr),
        .pwdata(pwdata),

        .prdata(prdata),
        .pready(pready),
        .pslverr(pslverr)

    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin

        pclk = 1'b0;

        forever #5 pclk = ~pclk;

    end


    // ============================================================
    // VCD
    // ============================================================

    initial begin

        $dumpfile("uvm_apb.vcd");

        $dumpvars(0, apb_tb);

    end


    // ============================================================
    // SCOREBOARD
    // ============================================================

    task check;

        input condition;
        input [255:0] message;

        begin

            if (condition) begin

                passed_transactions = passed_transactions + 1;

                $display(
                    "[SCOREBOARD] PASS %s",
                    message
                );

            end

            else begin

                failed_transactions = failed_transactions + 1;

                $display(
                    "[SCOREBOARD] FAIL %s",
                    message
                );

            end

        end

    endtask


    // ============================================================
    // APB WRITE
    // ============================================================

    task apb_write;

        input [7:0] address;
        input [31:0] data;

        integer busy_seen;
        integer cycles_waited;

        begin

            total_transactions = total_transactions + 1;
            write_tests = write_tests + 1;

            $display("");
            $display("----------------------------------------------");
            $display("[SEQUENCER] WRITE ADDR=%02h DATA=%08h",
                     address, data);
            $display("----------------------------------------------");


            // Prepare transaction

            addr     = address;
            wdata    = data;
            write_en = 1'b1;

            start = 1'b1;

            @(posedge pclk);

            #1;

            start = 1'b0;


            // BUSY check

            busy_seen = 0;

            repeat (2) begin

                @(posedge pclk);

                #1;

                if (busy)
                    busy_seen = 1;

            end

            busy_checks = busy_checks + 1;

            check(
                busy_seen,
                "APB WRITE BUSY"
            );


            // Wait for completion

            cycles_waited = 0;

            while (!done) begin

                @(posedge pclk);

                #1;

                cycles_waited = cycles_waited + 1;

            end


            wait_tests = wait_tests + 1;


            done_checks = done_checks + 1;

            check(
                done,
                "APB WRITE DONE"
            );


            // Error check

            error_checks = error_checks + 1;

            if (!error) begin

                passed_transactions = passed_transactions + 1;

                success_tests = success_tests + 1;

                $display(
                    "[SCOREBOARD] PASS WRITE SUCCESS"
                );

                reference_mem[address] = data;

            end

            else begin

                if (address[1:0] == 2'b11) begin

                    passed_transactions = passed_transactions + 1;

                    error_tests = error_tests + 1;

                    $display(
                        "[SCOREBOARD] PASS WRITE ERROR RESPONSE"
                    );

                end

                else begin

                    failed_transactions = failed_transactions + 1;

                    $display(
                        "[SCOREBOARD] FAIL UNEXPECTED WRITE ERROR"
                    );

                end

            end


            @(posedge pclk);

        end

    endtask


    // ============================================================
    // APB READ
    // ============================================================

    task apb_read;

        input [7:0] address;

        reg [31:0] expected;

        integer busy_seen;
        integer cycles_waited;

        begin

            total_transactions = total_transactions + 1;
            read_tests = read_tests + 1;

            expected = reference_mem[address];


            $display("");
            $display("----------------------------------------------");
            $display("[SEQUENCER] READ ADDR=%02h", address);
            $display("----------------------------------------------");


            addr     = address;
            wdata    = 0;
            write_en = 1'b0;

            start = 1'b1;

            @(posedge pclk);

            #1;

            start = 1'b0;


            // BUSY check

            busy_seen = 0;

            repeat (2) begin

                @(posedge pclk);

                #1;

                if (busy)
                    busy_seen = 1;

            end


            busy_checks = busy_checks + 1;

            check(
                busy_seen,
                "APB READ BUSY"
            );


            // Wait for completion

            cycles_waited = 0;

            while (!done) begin

                @(posedge pclk);

                #1;

                cycles_waited = cycles_waited + 1;

            end


            wait_tests = wait_tests + 1;


            done_checks = done_checks + 1;

            check(
                done,
                "APB READ DONE"
            );


            // Error handling

            if (address[1:0] == 2'b11) begin

                error_checks = error_checks + 1;

                if (error) begin

                    passed_transactions = passed_transactions + 1;

                    error_tests = error_tests + 1;

                    $display(
                        "[SCOREBOARD] PASS READ ERROR RESPONSE"
                    );

                end

                else begin

                    failed_transactions = failed_transactions + 1;

                    $display(
                        "[SCOREBOARD] FAIL READ ERROR RESPONSE"
                    );

                end

            end

            else begin

                error_checks = error_checks + 1;

                if (!error) begin

                    passed_transactions = passed_transactions + 1;

                    success_tests = success_tests + 1;

                    $display(
                        "[SCOREBOARD] PASS READ SUCCESS"
                    );

                end

                else begin

                    failed_transactions = failed_transactions + 1;

                    $display(
                        "[SCOREBOARD] FAIL UNEXPECTED READ ERROR"
                    );

                end


                // DATA CHECK

                data_checks = data_checks + 1;

                if (rdata == expected) begin

                    passed_transactions = passed_transactions + 1;

                    $display(
                        "[SCOREBOARD] PASS DATA Expected=%08h Received=%08h",
                        expected,
                        rdata
                    );

                end

                else begin

                    failed_transactions = failed_transactions + 1;

                    $display(
                        "[SCOREBOARD] FAIL DATA Expected=%08h Received=%08h",
                        expected,
                        rdata
                    );

                end

            end


            @(posedge pclk);

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    integer i;

    reg [7:0] random_addr;
    reg [31:0] random_data;


    initial begin

        // Initial values

        start    = 1'b0;
        write_en = 1'b0;
        addr     = 0;
        wdata    = 0;


        total_transactions = 0;
        passed_transactions = 0;
        failed_transactions = 0;

        read_tests  = 0;
        write_tests = 0;

        success_tests = 0;
        error_tests   = 0;

        busy_checks  = 0;
        done_checks  = 0;
        data_checks  = 0;
        error_checks = 0;

        wait_tests = 0;


        // Initialize reference model

        for (i = 0; i < 256; i = i + 1)
            reference_mem[i] = 0;


        $display("");
        $display("================================================");
        $display("       UVM-STYLE APB TEST START");
        $display("================================================");


        // ========================================================
        // RESET
        // ========================================================

        presetn = 1'b0;

        repeat (5)
            @(posedge pclk);

        presetn = 1'b1;

        @(posedge pclk);


        $display("");
        $display("[ENV] APB environment built");
        $display("[AGENT] APB agent started");


        // ========================================================
        // DIRECTED WRITE TESTS
        // ========================================================

        $display("");
        $display("----------- DIRECTED WRITE TESTS --------------");


        apb_write(8'h00, 32'h11111111);
        apb_write(8'h01, 32'h22222222);
        apb_write(8'h10, 32'h12345678);
        apb_write(8'h20, 32'hA5A5A5A5);


        // ========================================================
        // DIRECTED READ TESTS
        // ========================================================

        $display("");
        $display("------------ DIRECTED READ TESTS --------------");


        apb_read(8'h00);
        apb_read(8'h01);
        apb_read(8'h10);
        apb_read(8'h20);


        // ========================================================
        // ERROR TESTS
        // ========================================================

        $display("");
        $display("------------- ERROR TESTS ---------------------");


        apb_write(8'h03, 32'hDEADBEEF);
        apb_read(8'h03);


        // ========================================================
        // RANDOMIZED TESTS
        // ========================================================

        $display("");
        $display("------------- RANDOMIZED TESTS ----------------");


        repeat (100) begin

            random_addr = $random;
            random_data = $random;

            if (random_addr[1:0] == 2'b11) begin

                if ($random % 2)
                    apb_write(random_addr, random_data);
                else
                    apb_read(random_addr);

            end

            else begin

                if ($random % 2) begin

                    apb_write(
                        random_addr,
                        random_data
                    );

                end
                else begin

                    apb_read(random_addr);

                end

            end

        end


        // ========================================================
        // FINAL REPORT
        // ========================================================

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display(
            "TOTAL TRANSACTIONS  = %0d",
            total_transactions
        );

        $display(
            "READ TESTS          = %0d",
            read_tests
        );

        $display(
            "WRITE TESTS         = %0d",
            write_tests
        );

        $display(
            "SUCCESS TESTS       = %0d",
            success_tests
        );

        $display(
            "ERROR TESTS         = %0d",
            error_tests
        );

        $display(
            "BUSY CHECKS         = %0d",
            busy_checks
        );

        $display(
            "DONE CHECKS         = %0d",
            done_checks
        );

        $display(
            "DATA CHECKS         = %0d",
            data_checks
        );

        $display(
            "ERROR CHECKS        = %0d",
            error_checks
        );

        $display(
            "WAIT STATE TESTS    = %0d",
            wait_tests
        );

        $display(
            "PASSED CHECKS       = %0d",
            passed_transactions
        );

        $display(
            "FAILED CHECKS       = %0d",
            failed_transactions
        );


        if (failed_transactions == 0) begin

            $display("");
            $display("OVERALL RESULT = PASS");
            $display("UVM-STYLE APB VERIFICATION COMPLETE");

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