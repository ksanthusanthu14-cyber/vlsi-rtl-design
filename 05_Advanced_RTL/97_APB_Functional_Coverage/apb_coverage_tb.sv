`timescale 1ns/1ps

module apb_coverage_tb;

    parameter ADDR_WIDTH = 8;
    parameter DATA_WIDTH = 8;

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
    // MASTER CONTROL
    // ============================================================

    logic                  start;
    logic                  write;
    logic [ADDR_WIDTH-1:0] addr;
    logic [DATA_WIDTH-1:0] wdata;

    logic [DATA_WIDTH-1:0] rdata;
    logic                  done;
    logic                  error;
    logic                  busy;

    // ============================================================
    // APB SIGNALS
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
    // ERROR INJECTION
    // ============================================================

    logic error_inject;

    // ============================================================
    // INSTANCES
    // ============================================================

    apb_master #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) master (
        .clk     (clk),
        .rst     (rst),

        .start   (start),
        .write   (write),
        .addr    (addr),
        .wdata   (wdata),

        .rdata   (rdata),
        .done    (done),
        .error   (error),
        .busy    (busy),

        .psel    (psel),
        .penable (penable),
        .pwrite  (pwrite),
        .paddr   (paddr),
        .pwdata  (pwdata),

        .prdata  (prdata),
        .pready  (pready),
        .pslverr (pslverr)
    );

    apb_slave #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) slave (
        .clk          (clk),
        .rst          (rst),

        .psel         (psel),
        .penable      (penable),
        .pwrite       (pwrite),
        .paddr        (paddr),
        .pwdata       (pwdata),

        .error_inject (error_inject),

        .prdata       (prdata),
        .pready       (pready),
        .pslverr      (pslverr)
    );

    // ============================================================
    // EXPECTED MEMORY MODEL
    // ============================================================

    reg [7:0] expected_mem [0:255];

    // ============================================================
    // TEST COUNTERS
    // ============================================================

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    integer read_count;
    integer write_count;

    integer success_count;
    integer error_count;

    integer wait_count;
    integer no_wait_count;

    integer timeout;

    integer i;

    reg [7:0] random_addr;
    reg [7:0] random_data;

    // ============================================================
    // COVERAGE
    //
    // OPERATION
    //
    // 0 = READ
    // 1 = WRITE
    // ============================================================

    integer operation_hits [0:1];

    // ============================================================
    // ADDRESS CLASS
    //
    // 0 = LOW
    // 1 = MID
    // 2 = HIGH
    // 3 = BOUNDARY
    // ============================================================

    integer address_hits [0:3];

    // ============================================================
    // RESULT
    //
    // 0 = SUCCESS
    // 1 = ERROR
    // ============================================================

    integer result_hits [0:1];

    // ============================================================
    // WAIT STATE
    //
    // 0 = NO WAIT
    // 1 = WAIT
    // ============================================================

    integer wait_hits [0:1];

    // ============================================================
    // OPERATION x RESULT
    // ============================================================

    integer operation_result_hits [0:1][0:1];

    // ============================================================
    // ADDRESS x OPERATION
    // ============================================================

    integer address_operation_hits [0:3][0:1];

    // ============================================================
    // WAIT x OPERATION
    // ============================================================

    integer wait_operation_hits [0:1][0:1];

    // ============================================================
    // ADDRESS x RESULT
    // ============================================================

    integer address_result_hits [0:3][0:1];

    // ============================================================
    // COVERAGE TOTALS
    // ============================================================

    integer operation_bins_hit;
    integer address_bins_hit;
    integer result_bins_hit;
    integer wait_bins_hit;

    integer operation_result_bins_hit;
    integer address_operation_bins_hit;
    integer wait_operation_bins_hit;
    integer address_result_bins_hit;

    integer total_coverage_bins;
    integer coverage_bins_hit;
    integer coverage_percent;

    // ============================================================
    // ADDRESS CLASS FUNCTION
    // ============================================================

    function integer get_address_class;

        input [7:0] a;

        begin

            if (a <= 8'h1F)
                get_address_class = 0;

            else if (a <= 8'h7F)
                get_address_class = 1;

            else if ((a >= 8'h80) &&
                     (a <= 8'hEF))
                get_address_class = 2;

            else
                get_address_class = 3;

        end

    endfunction

    // ============================================================
    // UPDATE COVERAGE
    // ============================================================

    task update_coverage;

        input       op_write;
        input [7:0] trans_addr;
        input       trans_error;
        input       trans_wait;

        integer op;
        integer addr_class;
        integer result;
        integer wait_class;

        begin

            if (op_write)
                op = 1;
            else
                op = 0;

            addr_class =
                get_address_class(trans_addr);

            if (trans_error)
                result = 1;
            else
                result = 0;

            if (trans_wait)
                wait_class = 1;
            else
                wait_class = 0;

            // ----------------------------------------------------
            // INDIVIDUAL
            // ----------------------------------------------------

            operation_hits[op] =
                operation_hits[op] + 1;

            address_hits[addr_class] =
                address_hits[addr_class] + 1;

            result_hits[result] =
                result_hits[result] + 1;

            wait_hits[wait_class] =
                wait_hits[wait_class] + 1;

            // ----------------------------------------------------
            // OPERATION x RESULT
            // ----------------------------------------------------

            operation_result_hits[op][result] =
                operation_result_hits[op][result] + 1;

            // ----------------------------------------------------
            // ADDRESS x OPERATION
            // ----------------------------------------------------

            address_operation_hits[addr_class][op] =
                address_operation_hits[addr_class][op] + 1;

            // ----------------------------------------------------
            // WAIT x OPERATION
            // ----------------------------------------------------

            wait_operation_hits[wait_class][op] =
                wait_operation_hits[wait_class][op] + 1;

            // ----------------------------------------------------
            // ADDRESS x RESULT
            // ----------------------------------------------------

            address_result_hits[addr_class][result] =
                address_result_hits[addr_class][result] + 1;

        end

    endtask

    // ============================================================
    // APB TRANSACTION
    // ============================================================

    task apb_transaction;

        input        trans_write;
        input [7:0]  trans_addr;
        input [7:0]  trans_wdata;
        input        inject_error;

        reg [7:0] expected_data;

        integer trans_wait;
        integer trans_error;
        integer local_timeout;

        begin

            total_tests =
                total_tests + 1;

            // ====================================================
            // WAIT CLASS
            // ====================================================

            if (trans_addr[7])
                trans_wait = 1;
            else
                trans_wait = 0;

            // ====================================================
            // EXPECTED ERROR
            // ====================================================

            if (inject_error ||
                ((trans_addr >= 8'hF0) &&
                 (trans_addr <= 8'hF7)))
                trans_error = 1;
            else
                trans_error = 0;

            // ====================================================
            // EXPECTED READ DATA
            // ====================================================

            expected_data =
                expected_mem[trans_addr];

            // ====================================================
            // START TRANSACTION
            // ====================================================

            @(posedge clk);
            #1;

            write = trans_write;
            addr  = trans_addr;
            wdata = trans_wdata;

            error_inject = inject_error;

            start = 1'b1;

            @(posedge clk);
            #1;

            start = 1'b0;

            // ====================================================
            // WAIT FOR DONE
            // ====================================================

            local_timeout = 0;

            while ((!done) &&
                   (local_timeout < 20)) begin

                @(posedge clk);
                #1;

                local_timeout =
                    local_timeout + 1;

            end

            // ====================================================
            // TIMEOUT
            // ====================================================

            if (local_timeout >= 20) begin

                failed_tests =
                    failed_tests + 1;

                $display(
                    "FAIL: TIMEOUT WRITE=%b ADDR=%02h",
                    trans_write,
                    trans_addr
                );

            end

            else begin

                // =================================================
                // ERROR CHECK
                // =================================================

                if (error != trans_error) begin

                    failed_tests =
                        failed_tests + 1;

                    $display(
                        "FAIL: WRITE=%b ADDR=%02h ERROR=%b EXPECTED=%b",
                        trans_write,
                        trans_addr,
                        error,
                        trans_error
                    );

                end

                // =================================================
                // READ DATA CHECK
                // =================================================

                else if ((!trans_write) &&
                         (!trans_error) &&
                         (rdata !== expected_data)) begin

                    failed_tests =
                        failed_tests + 1;

                    $display(
                        "FAIL: READ ADDR=%02h RDATA=%02h EXPECTED=%02h",
                        trans_addr,
                        rdata,
                        expected_data
                    );

                end

                else begin

                    passed_tests =
                        passed_tests + 1;

                    if (trans_write) begin

                        $display(
                            "PASS: WRITE ADDR=%02h DATA=%02h WAIT=%0d ERROR=%0d",
                            trans_addr,
                            trans_wdata,
                            trans_wait,
                            trans_error
                        );

                    end
                    else begin

                        $display(
                            "PASS: READ ADDR=%02h RDATA=%02h WAIT=%0d ERROR=%0d",
                            trans_addr,
                            rdata,
                            trans_wait,
                            trans_error
                        );

                    end

                end

            end

            // ====================================================
            // UPDATE EXPECTED MEMORY
            //
            // Only successful writes modify the expected model.
            // ====================================================

            if (trans_write &&
                !trans_error) begin

                expected_mem[trans_addr] =
                    trans_wdata;

            end

            // ====================================================
            // STATISTICS
            // ====================================================

            if (trans_write)
                write_count =
                    write_count + 1;
            else
                read_count =
                    read_count + 1;

            if (trans_error)
                error_count =
                    error_count + 1;
            else
                success_count =
                    success_count + 1;

            if (trans_wait)
                wait_count =
                    wait_count + 1;
            else
                no_wait_count =
                    no_wait_count + 1;

            // ====================================================
            // COVERAGE
            // ====================================================

            update_coverage(
                trans_write,
                trans_addr,
                trans_error,
                trans_wait
            );

            error_inject = 1'b0;

            @(posedge clk);
            #1;

        end

    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // ========================================================
        // INITIALIZE
        // ========================================================

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        read_count  = 0;
        write_count = 0;

        success_count = 0;
        error_count   = 0;

        wait_count    = 0;
        no_wait_count = 0;

        start = 1'b0;
        write = 1'b0;
        addr  = 8'h00;
        wdata = 8'h00;

        error_inject = 1'b0;

        // ========================================================
        // EXPECTED MEMORY INITIALIZATION
        // ========================================================

        for (i = 0; i < 256; i = i + 1)
            expected_mem[i] = 8'h00;

        // ========================================================
        // COVERAGE INITIALIZATION
        // ========================================================

        for (i = 0; i < 2; i = i + 1) begin

            operation_hits[i] = 0;
            result_hits[i]    = 0;
            wait_hits[i]      = 0;

            operation_result_hits[i][0] = 0;
            operation_result_hits[i][1] = 0;

            wait_operation_hits[i][0] = 0;
            wait_operation_hits[i][1] = 0;

        end

        for (i = 0; i < 4; i = i + 1) begin

            address_hits[i] = 0;

            address_operation_hits[i][0] = 0;
            address_operation_hits[i][1] = 0;

            address_result_hits[i][0] = 0;
            address_result_hits[i][1] = 0;

        end

        // ========================================================
        // RESET
        // ========================================================

        rst = 1'b1;

        repeat (5)
            @(posedge clk);

        #1;

        rst = 1'b0;

        repeat (2)
            @(posedge clk);

        // ========================================================
        // HEADER
        // ========================================================

        $display("");
        $display("==============================================");
        $display("APB FUNCTIONAL COVERAGE VERIFICATION");
        $display("==============================================");
        $display("");

        // ========================================================
        // DIRECTED SUCCESS TESTS
        // ========================================================

        $display("DIRECTED SUCCESS TESTS");
        $display("----------------------------------------------");

        // LOW WRITE
        apb_transaction(
            1'b1,
            8'h10,
            8'hA5,
            1'b0
        );

        // LOW READ
        apb_transaction(
            1'b0,
            8'h10,
            8'h00,
            1'b0
        );

        // MID WRITE
        apb_transaction(
            1'b1,
            8'h40,
            8'h3C,
            1'b0
        );

        // MID READ
        apb_transaction(
            1'b0,
            8'h40,
            8'h00,
            1'b0
        );

        // HIGH WRITE
        apb_transaction(
            1'b1,
            8'h80,
            8'h5A,
            1'b0
        );

        // HIGH READ
        apb_transaction(
            1'b0,
            8'h80,
            8'h00,
            1'b0
        );

        // ========================================================
        // NATURAL BOUNDARY ERRORS
        // ========================================================

        $display("");
        $display("BOUNDARY ERROR TESTS");
        $display("----------------------------------------------");

        apb_transaction(
            1'b1,
            8'hF0,
            8'h11,
            1'b0
        );

        apb_transaction(
            1'b0,
            8'hF1,
            8'h00,
            1'b0
        );

        apb_transaction(
            1'b1,
            8'hF2,
            8'h22,
            1'b0
        );

        apb_transaction(
            1'b0,
            8'hF3,
            8'h00,
            1'b0
        );

        // ========================================================
        // RANDOMIZED TESTS
        // ========================================================

        $display("");
        $display("RANDOMIZED TESTS");
        $display("----------------------------------------------");

        for (i = 0; i < 100; i = i + 1) begin

            random_addr = $random;
            random_data = $random;

            if (random_addr < 8'h10)
                random_addr = 8'h10;

            // Random transactions use natural boundary errors.

            apb_transaction(
                random_addr[0],
                random_addr,
                random_data,
                1'b0
            );

        end

        // ========================================================
        // COVERAGE CLOSURE
        // ========================================================

        $display("");
        $display("COVERAGE CLOSURE TESTS");
        $display("----------------------------------------------");

        // --------------------------------------------------------
        // LOW + READ + SUCCESS
        // --------------------------------------------------------

        apb_transaction(
            1'b0,
            8'h10,
            8'h00,
            1'b0
        );

        // --------------------------------------------------------
        // LOW + WRITE + SUCCESS
        // --------------------------------------------------------

        apb_transaction(
            1'b1,
            8'h02,
            8'h12,
            1'b0
        );

        // --------------------------------------------------------
        // MID + READ + SUCCESS
        // --------------------------------------------------------

        apb_transaction(
            1'b0,
            8'h40,
            8'h00,
            1'b0
        );

        // --------------------------------------------------------
        // MID + WRITE + SUCCESS
        // --------------------------------------------------------

        apb_transaction(
            1'b1,
            8'h60,
            8'h34,
            1'b0
        );

        // --------------------------------------------------------
        // HIGH + READ + SUCCESS
        // --------------------------------------------------------

        apb_transaction(
            1'b0,
            8'h80,
            8'h00,
            1'b0
        );

        // --------------------------------------------------------
        // HIGH + WRITE + SUCCESS
        // --------------------------------------------------------

        apb_transaction(
            1'b1,
            8'hA0,
            8'h56,
            1'b0
        );

        // ========================================================
        // ERROR COVERAGE
        //
        // LOW + ERROR
        // ========================================================

        apb_transaction(
            1'b0,
            8'h10,
            8'h00,
            1'b1
        );

        apb_transaction(
            1'b1,
            8'h11,
            8'h77,
            1'b1
        );

        // ========================================================
        // MID + ERROR
        // ========================================================

        apb_transaction(
            1'b0,
            8'h40,
            8'h00,
            1'b1
        );

        apb_transaction(
            1'b1,
            8'h41,
            8'h88,
            1'b1
        );

        // ========================================================
        // HIGH + ERROR
        // ========================================================

        apb_transaction(
            1'b0,
            8'h80,
            8'h00,
            1'b1
        );

        apb_transaction(
            1'b1,
            8'h81,
            8'h99,
            1'b1
        );

        // ========================================================
        // BOUNDARY + ERROR
        // ========================================================

        apb_transaction(
            1'b0,
            8'hF4,
            8'h00,
            1'b0
        );

        apb_transaction(
            1'b1,
            8'hF5,
            8'h78,
            1'b0
        );

        // ========================================================
        // CALCULATE COVERAGE
        // ========================================================

        operation_bins_hit = 0;
        address_bins_hit   = 0;
        result_bins_hit    = 0;
        wait_bins_hit      = 0;

        operation_result_bins_hit = 0;
        address_operation_bins_hit = 0;
        wait_operation_bins_hit = 0;
        address_result_bins_hit = 0;

        // ========================================================
        // INDIVIDUAL
        // ========================================================

        for (i = 0; i < 2; i = i + 1) begin

            if (operation_hits[i] > 0)
                operation_bins_hit =
                    operation_bins_hit + 1;

            if (result_hits[i] > 0)
                result_bins_hit =
                    result_bins_hit + 1;

            if (wait_hits[i] > 0)
                wait_bins_hit =
                    wait_bins_hit + 1;

        end

        for (i = 0; i < 4; i = i + 1) begin

            if (address_hits[i] > 0)
                address_bins_hit =
                    address_bins_hit + 1;

        end

        // ========================================================
        // OPERATION x RESULT
        // ========================================================

        for (i = 0; i < 2; i = i + 1) begin

            if (operation_result_hits[i][0] > 0)
                operation_result_bins_hit =
                    operation_result_bins_hit + 1;

            if (operation_result_hits[i][1] > 0)
                operation_result_bins_hit =
                    operation_result_bins_hit + 1;

        end

        // ========================================================
        // ADDRESS x OPERATION
        // ========================================================

        for (i = 0; i < 4; i = i + 1) begin

            if (address_operation_hits[i][0] > 0)
                address_operation_bins_hit =
                    address_operation_bins_hit + 1;

            if (address_operation_hits[i][1] > 0)
                address_operation_bins_hit =
                    address_operation_bins_hit + 1;

        end

        // ========================================================
        // WAIT x OPERATION
        // ========================================================

        for (i = 0; i < 2; i = i + 1) begin

            if (wait_operation_hits[i][0] > 0)
                wait_operation_bins_hit =
                    wait_operation_bins_hit + 1;

            if (wait_operation_hits[i][1] > 0)
                wait_operation_bins_hit =
                    wait_operation_bins_hit + 1;

        end

        // ========================================================
        // ADDRESS x RESULT
        // ========================================================

        for (i = 0; i < 4; i = i + 1) begin

            if (address_result_hits[i][0] > 0)
                address_result_bins_hit =
                    address_result_bins_hit + 1;

            if (address_result_hits[i][1] > 0)
                address_result_bins_hit =
                    address_result_bins_hit + 1;

        end

        // ========================================================
        // TOTAL
        // ========================================================

        total_coverage_bins = 34;

        coverage_bins_hit =
            operation_bins_hit +
            address_bins_hit +
            result_bins_hit +
            wait_bins_hit +
            operation_result_bins_hit +
            address_operation_bins_hit +
            wait_operation_bins_hit +
            address_result_bins_hit;

        coverage_percent =
            (coverage_bins_hit * 100) /
            total_coverage_bins;

        // ========================================================
        // SUMMARY
        // ========================================================

        $display("");
        $display("==============================================");
        $display("APB FUNCTIONAL COVERAGE SUMMARY");
        $display("==============================================");

        $display("");

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

        $display("");

        $display(
            "READ TRANSACTIONS  = %0d",
            read_count
        );

        $display(
            "WRITE TRANSACTIONS = %0d",
            write_count
        );

        $display(
            "SUCCESSFUL         = %0d",
            success_count
        );

        $display(
            "ERROR              = %0d",
            error_count
        );

        $display(
            "NO WAIT            = %0d",
            no_wait_count
        );

        $display(
            "WAIT               = %0d",
            wait_count
        );

        // ========================================================
        // OPERATION
        // ========================================================

        $display("");
        $display("OPERATION COVERAGE");
        $display("----------------------------------------------");

        $display(
            "READ  = %0d",
            operation_hits[0]
        );

        $display(
            "WRITE = %0d",
            operation_hits[1]
        );

        // ========================================================
        // ADDRESS
        // ========================================================

        $display("");
        $display("ADDRESS CLASS COVERAGE");
        $display("----------------------------------------------");

        $display(
            "LOW      = %0d",
            address_hits[0]
        );

        $display(
            "MID      = %0d",
            address_hits[1]
        );

        $display(
            "HIGH     = %0d",
            address_hits[2]
        );

        $display(
            "BOUNDARY = %0d",
            address_hits[3]
        );

        // ========================================================
        // RESULT
        // ========================================================

        $display("");
        $display("RESULT COVERAGE");
        $display("----------------------------------------------");

        $display(
            "SUCCESS = %0d",
            result_hits[0]
        );

        $display(
            "ERROR   = %0d",
            result_hits[1]
        );

        // ========================================================
        // WAIT
        // ========================================================

        $display("");
        $display("WAIT-STATE COVERAGE");
        $display("----------------------------------------------");

        $display(
            "NO WAIT = %0d",
            wait_hits[0]
        );

        $display(
            "WAIT    = %0d",
            wait_hits[1]
        );

        // ========================================================
        // CROSSES
        // ========================================================

        $display("");
        $display("OPERATION x RESULT");
        $display("----------------------------------------------");

        $display(
            "READ  SUCCESS=%0d ERROR=%0d",
            operation_result_hits[0][0],
            operation_result_hits[0][1]
        );

        $display(
            "WRITE SUCCESS=%0d ERROR=%0d",
            operation_result_hits[1][0],
            operation_result_hits[1][1]
        );

        $display("");
        $display("ADDRESS x OPERATION");
        $display("----------------------------------------------");

        $display(
            "LOW      READ=%0d WRITE=%0d",
            address_operation_hits[0][0],
            address_operation_hits[0][1]
        );

        $display(
            "MID      READ=%0d WRITE=%0d",
            address_operation_hits[1][0],
            address_operation_hits[1][1]
        );

        $display(
            "HIGH     READ=%0d WRITE=%0d",
            address_operation_hits[2][0],
            address_operation_hits[2][1]
        );

        $display(
            "BOUNDARY READ=%0d WRITE=%0d",
            address_operation_hits[3][0],
            address_operation_hits[3][1]
        );

        $display("");
        $display("WAIT x OPERATION");
        $display("----------------------------------------------");

        $display(
            "NO WAIT READ=%0d WRITE=%0d",
            wait_operation_hits[0][0],
            wait_operation_hits[0][1]
        );

        $display(
            "WAIT    READ=%0d WRITE=%0d",
            wait_operation_hits[1][0],
            wait_operation_hits[1][1]
        );

        $display("");
        $display("ADDRESS x RESULT");
        $display("----------------------------------------------");

        $display(
            "LOW      SUCCESS=%0d ERROR=%0d",
            address_result_hits[0][0],
            address_result_hits[0][1]
        );

        $display(
            "MID      SUCCESS=%0d ERROR=%0d",
            address_result_hits[1][0],
            address_result_hits[1][1]
        );

        $display(
            "HIGH     SUCCESS=%0d ERROR=%0d",
            address_result_hits[2][0],
            address_result_hits[2][1]
        );

        $display(
            "BOUNDARY SUCCESS=%0d ERROR=%0d",
            address_result_hits[3][0],
            address_result_hits[3][1]
        );

        // ========================================================
        // COVERAGE TOTALS
        // ========================================================

        $display("");
        $display("==============================================");

        $display(
            "OPERATION BINS HIT          = %0d / 2",
            operation_bins_hit
        );

        $display(
            "ADDRESS BINS HIT            = %0d / 4",
            address_bins_hit
        );

        $display(
            "RESULT BINS HIT             = %0d / 2",
            result_bins_hit
        );

        $display(
            "WAIT BINS HIT               = %0d / 2",
            wait_bins_hit
        );

        $display(
            "OPERATION x RESULT          = %0d / 4",
            operation_result_bins_hit
        );

        $display(
            "ADDRESS x OPERATION         = %0d / 8",
            address_operation_bins_hit
        );

        $display(
            "WAIT x OPERATION            = %0d / 4",
            wait_operation_bins_hit
        );

        $display(
            "ADDRESS x RESULT            = %0d / 8",
            address_result_bins_hit
        );

        $display("");

        $display(
            "TOTAL COVERAGE BINS         = %0d / %0d",
            coverage_bins_hit,
            total_coverage_bins
        );

        $display(
            "FUNCTIONAL COVERAGE         = %0d%%",
            coverage_percent
        );

        // ========================================================
        // FINAL RESULT
        // ========================================================

        if ((failed_tests == 0) &&
            (coverage_percent == 100)) begin

            $display("");
            $display("OVERALL RESULT = PASS");

        end
        else begin

            $display("");
            $display("OVERALL RESULT = FAIL");

        end

        $display("");

        $display(
            "APB FUNCTIONAL COVERAGE VERIFICATION COMPLETE"
        );

        $display("==============================================");

        $finish;

    end

endmodule