`timescale 1ns/1ps

module fifo_random_tb;

    localparam DATA_WIDTH = 8;
    localparam DEPTH      = 16;

    logic clk;
    logic rst;

    logic wr_en;
    logic rd_en;
    logic [DATA_WIDTH-1:0] din;

    logic [DATA_WIDTH-1:0] dout;
    logic full;
    logic empty;
    logic [$clog2(DEPTH+1)-1:0] count;

    // ============================================================
    // DUT
    // ============================================================

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk   (clk),
        .rst   (rst),
        .wr_en (wr_en),
        .rd_en (rd_en),
        .din   (din),
        .dout  (dout),
        .full  (full),
        .empty (empty),
        .count (count)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    always #5 clk = ~clk;

    // ============================================================
    // REFERENCE MODEL
    // ============================================================

    logic [DATA_WIDTH-1:0] ref_mem [0:DEPTH-1];

    integer ref_wr_ptr;
    integer ref_rd_ptr;
    integer ref_count;

    // ============================================================
    // EXPECTED READ DATA
    // ============================================================

    logic [DATA_WIDTH-1:0] expected_dout;
    logic                  expected_read;

    // ============================================================
    // STATISTICS
    // ============================================================

    integer total_transactions;

    integer write_attempts;
    integer read_attempts;

    integer accepted_writes;
    integer accepted_reads;

    integer overflow_attempts;
    integer underflow_attempts;

    integer simultaneous_attempts;

    integer count_checks;
    integer status_checks;
    integer data_checks;

    integer pass_count;
    integer fail_count;

    integer i;

    // ============================================================
    // CHECK FIFO STATUS
    // ============================================================

    task automatic check_status;

        logic expected_full;
        logic expected_empty;

        begin

            expected_full  = (ref_count == DEPTH);
            expected_empty = (ref_count == 0);

            #1;

            // COUNT
            count_checks = count_checks + 1;

            if (count !== ref_count) begin

                $display(
                    "FAIL: COUNT | DUT=%0d EXPECTED=%0d",
                    count,
                    ref_count
                );

                fail_count = fail_count + 1;

            end
            else begin

                pass_count = pass_count + 1;

            end

            // FULL
            status_checks = status_checks + 1;

            if (full !== expected_full) begin

                $display(
                    "FAIL: FULL | DUT=%0d EXPECTED=%0d",
                    full,
                    expected_full
                );

                fail_count = fail_count + 1;

            end
            else begin

                pass_count = pass_count + 1;

            end

            // EMPTY
            status_checks = status_checks + 1;

            if (empty !== expected_empty) begin

                $display(
                    "FAIL: EMPTY | DUT=%0d EXPECTED=%0d",
                    empty,
                    expected_empty
                );

                fail_count = fail_count + 1;

            end
            else begin

                pass_count = pass_count + 1;

            end

        end

    endtask

    // ============================================================
    // RESET
    // ============================================================

    task automatic reset_fifo;

        begin

            rst   = 1'b1;
            wr_en = 1'b0;
            rd_en = 1'b0;
            din   = 8'h00;

            repeat (3)
                @(posedge clk);

            #1;

            rst = 1'b0;

            ref_wr_ptr = 0;
            ref_rd_ptr = 0;
            ref_count  = 0;

            expected_dout = 8'h00;
            expected_read = 1'b0;

            $display("PASS: RESET");

            check_status;

        end

    endtask

    // ============================================================
    // SINGLE TRANSACTION
    // ============================================================

    task automatic do_transaction(
        input logic                  do_write,
        input logic                  do_read,
        input logic [DATA_WIDTH-1:0] write_data
    );

        logic read_was_accepted;
        logic write_was_accepted;

        begin

            read_was_accepted  = 1'b0;
            write_was_accepted = 1'b0;

            expected_dout = 8'h00;
            expected_read = 1'b0;

            wr_en = do_write;
            rd_en = do_read;
            din   = write_data;

            total_transactions = total_transactions + 1;

            if (do_write)
                write_attempts = write_attempts + 1;

            if (do_read)
                read_attempts = read_attempts + 1;

            if (do_write && do_read)
                simultaneous_attempts =
                    simultaneous_attempts + 1;

            // ----------------------------------------------------
            // Determine accepted READ before modifying model
            // ----------------------------------------------------

            if (do_read) begin

                if (ref_count > 0) begin

                    expected_dout =
                        ref_mem[ref_rd_ptr];

                    expected_read = 1'b1;
                    read_was_accepted = 1'b1;

                end
                else begin

                    underflow_attempts =
                        underflow_attempts + 1;

                end

            end

            // ----------------------------------------------------
            // Determine accepted WRITE
            // ----------------------------------------------------

            if (do_write) begin

                if (ref_count < DEPTH) begin

                    write_was_accepted = 1'b1;

                end
                else begin

                    overflow_attempts =
                        overflow_attempts + 1;

                end

            end

            // ----------------------------------------------------
            // Apply transaction to DUT
            // ----------------------------------------------------

            @(posedge clk);

            #1;

            // ----------------------------------------------------
            // Check READ DATA
            // ----------------------------------------------------

            if (read_was_accepted) begin

                data_checks = data_checks + 1;

                if (dout !== expected_dout) begin

                    $display(
                        "FAIL: READ DATA | DUT=%02h EXPECTED=%02h COUNT=%0d",
                        dout,
                        expected_dout,
                        ref_count
                    );

                    fail_count = fail_count + 1;

                end
                else begin

                    pass_count = pass_count + 1;

                end

            end

            // ----------------------------------------------------
            // Update reference model
            //
            // Important:
            // simultaneous READ + WRITE is handled correctly.
            // ----------------------------------------------------

            if (read_was_accepted) begin

                if (ref_rd_ptr == DEPTH-1)
                    ref_rd_ptr = 0;
                else
                    ref_rd_ptr = ref_rd_ptr + 1;

                ref_count = ref_count - 1;

                accepted_reads =
                    accepted_reads + 1;

            end

            if (write_was_accepted) begin

                ref_mem[ref_wr_ptr] = write_data;

                if (ref_wr_ptr == DEPTH-1)
                    ref_wr_ptr = 0;
                else
                    ref_wr_ptr = ref_wr_ptr + 1;

                ref_count = ref_count + 1;

                accepted_writes =
                    accepted_writes + 1;

            end

            check_status;

            wr_en = 1'b0;
            rd_en = 1'b0;

        end

    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        $dumpfile("fifo_random.vcd");
        $dumpvars(0, fifo_random_tb);

        clk = 1'b0;
        rst = 1'b0;

        wr_en = 1'b0;
        rd_en = 1'b0;
        din   = 8'h00;

        ref_wr_ptr = 0;
        ref_rd_ptr = 0;
        ref_count  = 0;

        total_transactions = 0;

        write_attempts = 0;
        read_attempts  = 0;

        accepted_writes = 0;
        accepted_reads  = 0;

        overflow_attempts  = 0;
        underflow_attempts = 0;

        simultaneous_attempts = 0;

        count_checks  = 0;
        status_checks = 0;
        data_checks   = 0;

        pass_count = 0;
        fail_count = 0;

        for (i = 0; i < DEPTH; i = i + 1)
            ref_mem[i] = 8'h00;

        // ========================================================
        // HEADER
        // ========================================================

        $display("==============================================");
        $display("RANDOMIZED FIFO VERIFICATION");
        $display("==============================================");

        // ========================================================
        // RESET
        // ========================================================

        reset_fifo;

        // ========================================================
        // DIRECTED TESTS
        // ========================================================

        $display("");
        $display("DIRECTED FIFO TESTS");
        $display("----------------------------------------------");

        // Write known data
        do_transaction(1'b1, 1'b0, 8'h11);
        do_transaction(1'b1, 1'b0, 8'h22);
        do_transaction(1'b1, 1'b0, 8'h33);
        do_transaction(1'b1, 1'b0, 8'h44);

        // Read back in FIFO order
        do_transaction(1'b0, 1'b1, 8'h00);
        do_transaction(1'b0, 1'b1, 8'h00);
        do_transaction(1'b0, 1'b1, 8'h00);
        do_transaction(1'b0, 1'b1, 8'h00);

        // ========================================================
        // FILL FIFO
        // ========================================================

        $display("");
        $display("FILL FIFO TO FULL");
        $display("----------------------------------------------");

        for (i = 0; i < DEPTH; i = i + 1)
            do_transaction(
                1'b1,
                1'b0,
                8'hA0 + i
            );

        // ========================================================
        // OVERFLOW
        // ========================================================

        $display("");
        $display("OVERFLOW TEST");
        $display("----------------------------------------------");

        do_transaction(
            1'b1,
            1'b0,
            8'hFF
        );

        // ========================================================
        // READ WHILE FULL
        // ========================================================

        $display("");
        $display("READ FROM FULL FIFO");
        $display("----------------------------------------------");

        do_transaction(
            1'b0,
            1'b1,
            8'h00
        );

        // ========================================================
        // SIMULTANEOUS READ + WRITE
        // ========================================================

        $display("");
        $display("SIMULTANEOUS READ + WRITE");
        $display("----------------------------------------------");

        repeat (5) begin

            do_transaction(
                1'b1,
                1'b1,
                $urandom_range(0,255)
            );

        end

        // ========================================================
        // DRAIN FIFO
        // ========================================================

        $display("");
        $display("DRAIN FIFO");
        $display("----------------------------------------------");

        while (ref_count > 0) begin

            do_transaction(
                1'b0,
                1'b1,
                8'h00
            );

        end

        // ========================================================
        // UNDERFLOW
        // ========================================================

        $display("");
        $display("UNDERFLOW TEST");
        $display("----------------------------------------------");

        do_transaction(
            1'b0,
            1'b1,
            8'h00
        );

        // ========================================================
        // RANDOMIZED STRESS
        // ========================================================

        $display("");
        $display("1000 RANDOMIZED TRANSACTIONS");
        $display("----------------------------------------------");

        for (i = 0; i < 1000; i = i + 1) begin

            case ($urandom_range(0,3))

                // WRITE
                0:
                    do_transaction(
                        1'b1,
                        1'b0,
                        $urandom_range(0,255)
                    );

                // READ
                1:
                    do_transaction(
                        1'b0,
                        1'b1,
                        8'h00
                    );

                // BOTH
                2:
                    do_transaction(
                        1'b1,
                        1'b1,
                        $urandom_range(0,255)
                    );

                // IDLE
                default:
                    do_transaction(
                        1'b0,
                        1'b0,
                        8'h00
                    );

            endcase

        end

        // ========================================================
        // FINAL DRAIN
        // ========================================================

        $display("");
        $display("FINAL FIFO DRAIN");
        $display("----------------------------------------------");

        while (ref_count > 0) begin

            do_transaction(
                1'b0,
                1'b1,
                8'h00
            );

        end

        // ========================================================
        // FINAL CHECK
        // ========================================================

        check_status;

        // ========================================================
        // SUMMARY
        // ========================================================

        $display("");
        $display("==============================================");
        $display("RANDOMIZED FIFO VERIFICATION SUMMARY");
        $display("==============================================");

        $display(
            "TOTAL TRANSACTIONS = %0d",
            total_transactions
        );

        $display(
            "WRITE ATTEMPTS     = %0d",
            write_attempts
        );

        $display(
            "READ ATTEMPTS      = %0d",
            read_attempts
        );

        $display(
            "ACCEPTED WRITES    = %0d",
            accepted_writes
        );

        $display(
            "ACCEPTED READS     = %0d",
            accepted_reads
        );

        $display(
            "OVERFLOW ATTEMPTS  = %0d",
            overflow_attempts
        );

        $display(
            "UNDERFLOW ATTEMPTS = %0d",
            underflow_attempts
        );

        $display(
            "SIMULTANEOUS OPS   = %0d",
            simultaneous_attempts
        );

        $display("");
        $display(
            "COUNT CHECKS       = %0d",
            count_checks
        );

        $display(
            "STATUS CHECKS      = %0d",
            status_checks
        );

        $display(
            "DATA CHECKS        = %0d",
            data_checks
        );

        $display("");
        $display(
            "PASS CHECKS        = %0d",
            pass_count
        );

        $display(
            "FAIL CHECKS        = %0d",
            fail_count
        );

        $display("----------------------------------------------");

        if (fail_count == 0) begin

            $display("OVERALL RESULT = PASS");
            $display(
                "RANDOMIZED FIFO VERIFICATION COMPLETE"
            );

        end
        else begin

            $display("OVERALL RESULT = FAIL");

        end

        $display("==============================================");

        $finish;

    end

endmodule