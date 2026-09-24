`timescale 1ns/1ps

module fifo_sva_tb;

    localparam int DATA_WIDTH = 8;
    localparam int DEPTH      = 8;

    logic clk;
    logic rst;

    logic wr_en;
    logic rd_en;

    logic [DATA_WIDTH-1:0] wr_data;
    logic [DATA_WIDTH-1:0] rd_data;

    logic full;
    logic empty;

    logic [$clog2(DEPTH+1)-1:0] count;


    //============================================================
    // DUT
    //============================================================

    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),

        .wr_en(wr_en),
        .rd_en(rd_en),

        .wr_data(wr_data),
        .rd_data(rd_data),

        .full(full),
        .empty(empty),

        .count(count)
    );


    //============================================================
    // CLOCK
    //============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    //============================================================
    // ASSERTION MONITOR
    //
    // Icarus-compatible equivalent of SVA properties.
    //============================================================

    integer assertion_checks;
    integer assertion_passes;
    integer assertion_failures;


    task automatic assertion_pass;

        input string name;

        begin

            assertion_checks = assertion_checks + 1;
            assertion_passes = assertion_passes + 1;

            $display(
                "ASSERT PASS: %s",
                name
            );

        end

    endtask


    task automatic assertion_fail;

        input string name;

        begin

            assertion_checks  = assertion_checks + 1;
            assertion_failures = assertion_failures + 1;

            $display(
                "ASSERT FAIL: %s",
                name
            );

        end

    endtask


    //============================================================
    // PROPERTY 1
    //
    // COUNT must never exceed DEPTH.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (count <= DEPTH)
                assertion_pass(
                    "COUNT <= DEPTH"
                );
            else
                assertion_fail(
                    "COUNT <= DEPTH"
                );

        end

    end


    //============================================================
    // PROPERTY 2
    //
    // COUNT must remain valid.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (count >= 0)
                assertion_pass(
                    "COUNT >= 0"
                );
            else
                assertion_fail(
                    "COUNT >= 0"
                );

        end

    end


    //============================================================
    // PROPERTY 3
    //
    // count == 0 -> empty must be asserted.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (count == 0) begin

                if (empty)
                    assertion_pass(
                        "COUNT=0 -> EMPTY"
                    );
                else
                    assertion_fail(
                        "COUNT=0 -> EMPTY"
                    );

            end

        end

    end


    //============================================================
    // PROPERTY 4
    //
    // count > 0 -> FIFO must not be empty.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (count > 0) begin

                if (!empty)
                    assertion_pass(
                        "COUNT>0 -> !EMPTY"
                    );
                else
                    assertion_fail(
                        "COUNT>0 -> !EMPTY"
                    );

            end

        end

    end


    //============================================================
    // PROPERTY 5
    //
    // count == DEPTH -> full must be asserted.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (count == DEPTH) begin

                if (full)
                    assertion_pass(
                        "COUNT=DEPTH -> FULL"
                    );
                else
                    assertion_fail(
                        "COUNT=DEPTH -> FULL"
                    );

            end

        end

    end


    //============================================================
    // PROPERTY 6
    //
    // count < DEPTH -> FIFO must not be full.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (count < DEPTH) begin

                if (!full)
                    assertion_pass(
                        "COUNT<DEPTH -> !FULL"
                    );
                else
                    assertion_fail(
                        "COUNT<DEPTH -> !FULL"
                    );

            end

        end

    end


    //============================================================
    // PROPERTY 7
    //
    // Valid write increments count.
    //============================================================

    logic [$clog2(DEPTH+1)-1:0] previous_count;

    logic previous_valid_write;
    logic previous_valid_read;


    always @(posedge clk) begin

        if (rst) begin

            previous_count      <= 0;
            previous_valid_write <= 0;
            previous_valid_read  <= 0;

        end

        else begin

            // Check previous cycle's valid WRITE.

            if (previous_valid_write &&
                !previous_valid_read) begin

                if (count == previous_count + 1)
                    assertion_pass(
                        "VALID WRITE -> COUNT+1"
                    );
                else
                    assertion_fail(
                        "VALID WRITE -> COUNT+1"
                    );

            end


            // Check previous cycle's valid READ.

            if (previous_valid_read &&
                !previous_valid_write) begin

                if (count == previous_count - 1)
                    assertion_pass(
                        "VALID READ -> COUNT-1"
                    );
                else
                    assertion_fail(
                        "VALID READ -> COUNT-1"
                    );

            end


            // Save current state for next cycle.

            previous_count <= count;

            previous_valid_write <=
                wr_en && !full;

            previous_valid_read <=
                rd_en && !empty;

        end

    end


    //============================================================
    // PROPERTY 8
    //
    // Simultaneous valid read/write preserves count.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if ((wr_en && !full) &&
                (rd_en && !empty)) begin

                if (count == previous_count)
                    assertion_pass(
                        "SIMULTANEOUS READ/WRITE -> COUNT SAME"
                    );
                else
                    assertion_fail(
                        "SIMULTANEOUS READ/WRITE -> COUNT SAME"
                    );

            end

        end

    end


    //============================================================
    // DIRECTED TEST COUNTERS
    //============================================================

    integer pass_count;
    integer fail_count;


    task automatic check_state;

        input string name;
        input logic expected_empty;
        input logic expected_full;

        begin

            if ((empty === expected_empty) &&
                (full  === expected_full)) begin

                $display(
                    "PASS: %s | COUNT=%0d EMPTY=%b FULL=%b",
                    name,
                    count,
                    empty,
                    full
                );

                pass_count = pass_count + 1;

            end

            else begin

                $display(
                    "FAIL: %s | COUNT=%0d EMPTY=%b FULL=%b",
                    name,
                    count,
                    empty,
                    full
                );

                fail_count = fail_count + 1;

            end

        end

    endtask


    //============================================================
    // MAIN TEST
    //============================================================

    initial begin

        $dumpfile("fifo_sva.vcd");
        $dumpvars(0, fifo_sva_tb);

        pass_count = 0;
        fail_count = 0;

        assertion_checks   = 0;
        assertion_passes   = 0;
        assertion_failures = 0;

        wr_en   = 0;
        rd_en   = 0;
        wr_data = 0;

        previous_count       = 0;
        previous_valid_write = 0;
        previous_valid_read  = 0;

        rst = 1;

        repeat (2)
            @(posedge clk);

        rst = 0;

        @(posedge clk);


        //========================================================
        // TEST 1 — RESET
        //========================================================

        check_state(
            "RESET",
            1'b1,
            1'b0
        );


        //========================================================
        // TEST 2 — FOUR WRITES
        //========================================================

        repeat (4) begin

            @(negedge clk);

            wr_en   = 1;
            rd_en   = 0;

            wr_data = wr_data + 8'h11;

        end

        @(negedge clk);

        wr_en = 0;

        @(posedge clk);

        check_state(
            "AFTER 4 WRITES",
            1'b0,
            1'b0
        );


        //========================================================
        // TEST 3 — TWO READS
        //========================================================

        repeat (2) begin

            @(negedge clk);

            rd_en = 1;

        end

        @(negedge clk);

        rd_en = 0;

        @(posedge clk);

        check_state(
            "AFTER 2 READS",
            1'b0,
            1'b0
        );


        //========================================================
        // TEST 4 — FILL FIFO
        //========================================================

        repeat (6) begin

            @(negedge clk);

            wr_en   = 1;
            rd_en   = 0;

            wr_data = wr_data + 8'h10;

        end

        @(negedge clk);

        wr_en = 0;

        @(posedge clk);

        check_state(
            "FIFO FULL",
            1'b0,
            1'b1
        );


        //========================================================
        // TEST 5 — OVERFLOW
        //========================================================

        @(negedge clk);

        wr_en   = 1;
        wr_data = 8'hFF;

        @(posedge clk);

        @(negedge clk);

        wr_en = 0;

        @(posedge clk);

        check_state(
            "OVERFLOW BLOCKED",
            1'b0,
            1'b1
        );


        //========================================================
        // TEST 6 — DRAIN FIFO
        //========================================================

        repeat (8) begin

            @(negedge clk);

            rd_en = 1;

        end

        @(negedge clk);

        rd_en = 0;

        @(posedge clk);

        check_state(
            "FIFO EMPTY",
            1'b1,
            1'b0
        );


        //========================================================
        // TEST 7 — UNDERFLOW
        //========================================================

        @(negedge clk);

        rd_en = 1;

        @(posedge clk);

        @(negedge clk);

        rd_en = 0;

        @(posedge clk);

        check_state(
            "UNDERFLOW BLOCKED",
            1'b1,
            1'b0
        );


        //========================================================
        // SUMMARY
        //========================================================

        $display("");
        $display("==============================================");
        $display("FIFO ASSERTION VERIFICATION SUMMARY");
        $display("==============================================");

        $display(
            "DIRECTED CHECKS      = %0d",
            pass_count
        );

        $display(
            "DIRECTED FAILURES    = %0d",
            fail_count
        );

        $display(
            "ASSERTION CHECKS     = %0d",
            assertion_checks
        );

        $display(
            "ASSERTIONS PASSED   = %0d",
            assertion_passes
        );

        $display(
            "ASSERTIONS FAILED   = %0d",
            assertion_failures
        );

        $display("==============================================");

        if ((fail_count == 0) &&
            (assertion_failures == 0))

            $display(
                "OVERALL RESULT = PASS"
            );

        else

            $display(
                "OVERALL RESULT = FAIL"
            );

        $display("==============================================");

        $display(
            "FIFO ASSERTION VERIFICATION COMPLETE"
        );

        $finish;

    end

endmodule