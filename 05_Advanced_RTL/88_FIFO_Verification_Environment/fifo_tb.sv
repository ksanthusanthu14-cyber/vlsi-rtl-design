`timescale 1ns/1ps

module fifo_verification_tb;

    localparam int DATA_WIDTH = 8;
    localparam int DEPTH      = 16;

    localparam int RANDOM_TESTS = 500;


    //==================================================
    // DUT SIGNALS
    //==================================================

    logic clk;
    logic rst;

    logic wr_en;
    logic [DATA_WIDTH-1:0] wr_data;

    logic rd_en;
    logic [DATA_WIDTH-1:0] rd_data;

    logic full;
    logic empty;

    logic [$clog2(DEPTH+1)-1:0] count;


    //==================================================
    // REFERENCE MODEL
    //==================================================

    logic [DATA_WIDTH-1:0] reference_mem [0:DEPTH-1];

    integer ref_wr_ptr;
    integer ref_rd_ptr;
    integer ref_count;


    //==================================================
    // SCOREBOARD COUNTERS
    //==================================================

    integer total_transactions;
    integer passed_transactions;
    integer failed_transactions;

    integer writes;
    integer reads;

    integer overflow_attempts;
    integer underflow_attempts;


    //==================================================
    // DUT
    //==================================================

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (

        .clk(clk),
        .rst(rst),

        .wr_en(wr_en),
        .wr_data(wr_data),

        .rd_en(rd_en),
        .rd_data(rd_data),

        .full(full),
        .empty(empty),

        .count(count)

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

    task automatic reset_fifo;

        begin

            rst    = 1'b1;
            wr_en  = 1'b0;
            rd_en  = 1'b0;
            wr_data = '0;

            ref_wr_ptr = 0;
            ref_rd_ptr = 0;
            ref_count  = 0;

            repeat (3)
                @(posedge clk);

            #1;

            rst = 1'b0;

            @(posedge clk);
            #1;

            if (!empty && count != 0) begin

                $display(
                    "FAIL: RESET STATE"
                );

                failed_transactions =
                    failed_transactions + 1;

            end

            else begin

                $display(
                    "PASS: RESET -> FIFO EMPTY"
                );

            end

        end

    endtask


    //==================================================
    // CHECK STATUS
    //==================================================

    task automatic check_status;

        begin

            #1;

            total_transactions =
                total_transactions + 1;


            if ((count == ref_count) &&
                (empty == (ref_count == 0)) &&
                (full == (ref_count == DEPTH))) begin

                passed_transactions =
                    passed_transactions + 1;

            end

            else begin

                failed_transactions =
                    failed_transactions + 1;

                $display("");

                $display(
                    "*************** SCOREBOARD FAILURE ***************"
                );

                $display(
                    "EXPECTED COUNT = %0d",
                    ref_count
                );

                $display(
                    "DUT COUNT      = %0d",
                    count
                );

                $display(
                    "EXPECTED EMPTY = %b",
                    (ref_count == 0)
                );

                $display(
                    "DUT EMPTY      = %b",
                    empty
                );

                $display(
                    "EXPECTED FULL  = %b",
                    (ref_count == DEPTH)
                );

                $display(
                    "DUT FULL       = %b",
                    full
                );

                $display(
                    "***************************************************"
                );

            end

        end

    endtask


    //==================================================
    // WRITE TRANSACTION
    //==================================================

    task automatic write_transaction(
        input logic [DATA_WIDTH-1:0] data
    );

        begin

            wr_en   = 1'b1;
            rd_en   = 1'b0;
            wr_data = data;

            @(posedge clk);
            #1;


            if (ref_count < DEPTH) begin

                reference_mem[ref_wr_ptr] = data;

                if (ref_wr_ptr == DEPTH-1)
                    ref_wr_ptr = 0;
                else
                    ref_wr_ptr = ref_wr_ptr + 1;

                ref_count = ref_count + 1;

                writes = writes + 1;

                $display(
                    "WRITE: DATA=%h COUNT=%0d",
                    data,
                    ref_count
                );

            end

            else begin

                overflow_attempts =
                    overflow_attempts + 1;

                $display(
                    "OVERFLOW ATTEMPT: DATA=%h COUNT=%0d",
                    data,
                    ref_count
                );

            end


            wr_en = 1'b0;

            check_status();

        end

    endtask


    //==================================================
    // READ TRANSACTION
    //==================================================

    task automatic read_transaction;

        logic [DATA_WIDTH-1:0] expected_data;

        begin

            wr_en = 1'b0;
            rd_en = 1'b1;

            @(posedge clk);
            #1;


            if (ref_count > 0) begin

                expected_data =
                    reference_mem[ref_rd_ptr];

                if (rd_data === expected_data) begin

                    $display(
                        "READ: DATA=%h EXPECTED=%h COUNT=%0d",
                        rd_data,
                        expected_data,
                        ref_count - 1
                    );

                end

                else begin

                    $display(
                        "FAIL: READ DATA=%h EXPECTED=%h",
                        rd_data,
                        expected_data
                    );

                    failed_transactions =
                        failed_transactions + 1;

                end


                if (ref_rd_ptr == DEPTH-1)
                    ref_rd_ptr = 0;
                else
                    ref_rd_ptr = ref_rd_ptr + 1;

                ref_count = ref_count - 1;

                reads = reads + 1;

            end

            else begin

                underflow_attempts =
                    underflow_attempts + 1;

                $display(
                    "UNDERFLOW ATTEMPT: FIFO EMPTY"
                );

            end


            rd_en = 1'b0;

            check_status();

        end

    endtask


    //==================================================
    // SIMULTANEOUS READ / WRITE
    //==================================================

    task automatic simultaneous_transaction(
        input logic [DATA_WIDTH-1:0] write_data
    );

        logic [DATA_WIDTH-1:0] expected_data;

        begin

            wr_en   = 1'b1;
            rd_en   = 1'b1;
            wr_data = write_data;


            if (ref_count > 0)
                expected_data =
                    reference_mem[ref_rd_ptr];
            else
                expected_data = '0;


            @(posedge clk);
            #1;


            //========================================
            // READ SIDE
            //========================================

            if (ref_count > 0) begin

                if (rd_data === expected_data) begin

                    $display(
                        "SIMULTANEOUS READ: DATA=%h EXPECTED=%h",
                        rd_data,
                        expected_data
                    );

                end

                else begin

                    $display(
                        "FAIL: SIMULTANEOUS READ DATA=%h EXPECTED=%h",
                        rd_data,
                        expected_data
                    );

                    failed_transactions =
                        failed_transactions + 1;

                end


                if (ref_rd_ptr == DEPTH-1)
                    ref_rd_ptr = 0;
                else
                    ref_rd_ptr = ref_rd_ptr + 1;

                ref_count = ref_count - 1;

                reads = reads + 1;

            end


            //========================================
            // WRITE SIDE
            //========================================

            if (ref_count < DEPTH) begin

                reference_mem[ref_wr_ptr] =
                    write_data;

                if (ref_wr_ptr == DEPTH-1)
                    ref_wr_ptr = 0;
                else
                    ref_wr_ptr = ref_wr_ptr + 1;

                ref_count = ref_count + 1;

                writes = writes + 1;

                $display(
                    "SIMULTANEOUS WRITE: DATA=%h",
                    write_data
                );

            end

            else begin

                overflow_attempts =
                    overflow_attempts + 1;

            end


            wr_en = 1'b0;
            rd_en = 1'b0;


            check_status();

        end

    endtask


    //==================================================
    // RANDOM TRANSACTION
    //==================================================

    task automatic random_transaction;

        integer operation;
        logic [DATA_WIDTH-1:0] random_data;

        begin

            operation  = $urandom_range(0, 99);

            random_data =
                $urandom_range(0, 255);


            if (operation < 45) begin

                // WRITE

                write_transaction(random_data);

            end

            else if (operation < 90) begin

                // READ

                read_transaction();

            end

            else begin

                // SIMULTANEOUS

                simultaneous_transaction(
                    random_data
                );

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
            "fifo_verification.vcd"
        );

        $dumpvars(
            0,
            fifo_verification_tb
        );


        //================================================
        // INITIALIZATION
        //================================================

        total_transactions = 0;
        passed_transactions = 0;
        failed_transactions = 0;

        writes = 0;
        reads = 0;

        overflow_attempts = 0;
        underflow_attempts = 0;

        wr_en = 0;
        rd_en = 0;
        wr_data = 0;


        //================================================
        // RESET
        //================================================

        reset_fifo();


        //================================================
        // DIRECTED WRITE TEST
        //================================================

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "TEST 1: DIRECTED FIFO WRITE"
        );

        $display(
            "=============================================="
        );


        write_transaction(8'h11);
        write_transaction(8'h22);
        write_transaction(8'h33);
        write_transaction(8'h44);


        //================================================
        // DIRECTED READ TEST
        //================================================

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "TEST 2: DIRECTED FIFO READ"
        );

        $display(
            "=============================================="
        );


        read_transaction();
        read_transaction();
        read_transaction();
        read_transaction();


        //================================================
        // FILL FIFO
        //================================================

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "TEST 3: FILL FIFO TO FULL"
        );

        $display(
            "=============================================="
        );


        for (i = 0; i < DEPTH; i = i + 1)

            write_transaction(
                8'hA0 + i
            );


        //================================================
        // OVERFLOW
        //================================================

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "TEST 4: OVERFLOW PROTECTION"
        );

        $display(
            "=============================================="
        );


        write_transaction(8'hFF);
        write_transaction(8'hEE);


        //================================================
        // DRAIN FIFO
        //================================================

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "TEST 5: DRAIN FIFO"
        );

        $display(
            "=============================================="
        );


        for (i = 0; i < DEPTH; i = i + 1)

            read_transaction();


        //================================================
        // UNDERFLOW
        //================================================

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "TEST 6: UNDERFLOW PROTECTION"
        );

        $display(
            "=============================================="
        );


        read_transaction();
        read_transaction();


        //================================================
        // RANDOMIZED TEST
        //================================================

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "TEST 7: RANDOMIZED FIFO VERIFICATION"
        );

        $display(
            "=============================================="
        );


        for (i = 0; i < RANDOM_TESTS; i = i + 1)

            random_transaction();


        //================================================
        // FINAL DRAIN
        //================================================

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "TEST 8: FINAL FIFO DRAIN"
        );

        $display(
            "=============================================="
        );


        while (ref_count > 0)

            read_transaction();


        //================================================
        // FINAL CHECK
        //================================================

        check_status();


        //================================================
        // SUMMARY
        //================================================

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "FIFO VERIFICATION SUMMARY"
        );

        $display(
            "=============================================="
        );


        $display(
            "TOTAL CHECKS       = %0d",
            total_transactions
        );


        $display(
            "PASSED CHECKS      = %0d",
            passed_transactions
        );


        $display(
            "FAILED CHECKS      = %0d",
            failed_transactions
        );


        $display(
            "TOTAL WRITES       = %0d",
            writes
        );


        $display(
            "TOTAL READS        = %0d",
            reads
        );


        $display(
            "OVERFLOW ATTEMPTS  = %0d",
            overflow_attempts
        );


        $display(
            "UNDERFLOW ATTEMPTS = %0d",
            underflow_attempts
        );


        $display("");
        $display(
            "=============================================="
        );


        if (failed_transactions == 0) begin

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
            "FIFO VERIFICATION ENVIRONMENT COMPLETE"
        );


        $display(
            "=============================================="
        );


        $finish;

    end

endmodule