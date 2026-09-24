`timescale 1ns/1ps

module data_acquisition_tb;

    localparam DATA_WIDTH = 8;
    localparam FIFO_DEPTH = 8;

    logic clk;
    logic rst;

    logic source_enable;
    logic consumer_read;

    logic [DATA_WIDTH-1:0] data_out;
    logic data_valid;

    logic fifo_full;
    logic fifo_empty;

    logic [$clog2(FIFO_DEPTH+1)-1:0] fifo_count;

    logic overflow;
    logic underflow;

    integer checks;
    integer passed;
    integer failed;

    integer expected_data;


    // ============================================================
    // DUT
    // ============================================================

    data_acquisition #(
        .DATA_WIDTH(DATA_WIDTH),
        .FIFO_DEPTH(FIFO_DEPTH)
    ) dut (
        .clk           (clk),
        .rst           (rst),

        .source_enable (source_enable),
        .consumer_read (consumer_read),

        .data_out      (data_out),
        .data_valid    (data_valid),

        .fifo_full     (fifo_full),
        .fifo_empty    (fifo_empty),

        .fifo_count    (fifo_count),

        .overflow      (overflow),
        .underflow     (underflow)
    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ============================================================
    // CHECK
    // ============================================================

    task check;
        input condition;
        input [255:0] message;

        begin

            checks = checks + 1;

            if (condition) begin
                passed = passed + 1;
                $display("PASS: %s", message);
            end

            else begin
                failed = failed + 1;
                $display("FAIL: %s", message);
            end

        end
    endtask


    // ============================================================
    // RESET
    // ============================================================

    task reset_dut;

        begin

            // Drive reset away from active clock edge
            @(negedge clk);

            rst = 1'b1;
            source_enable = 1'b0;
            consumer_read = 1'b0;

            repeat (3)
                @(negedge clk);

            rst = 1'b0;

            @(negedge clk);

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        checks = 0;
        passed = 0;
        failed = 0;

        expected_data = 1;

        rst = 1'b0;
        source_enable = 1'b0;
        consumer_read = 1'b0;


        $display("");
        $display("================================================");
        $display("   FIFO-BASED DATA ACQUISITION SYSTEM TEST");
        $display("================================================");
        $display("");


        // ========================================================
        // TEST 1 — RESET
        // ========================================================

        $display("TEST 1: RESET");

        reset_dut();

        check(
            fifo_count == 0,
            "FIFO count = 0 after reset"
        );

        check(
            fifo_empty == 1'b1,
            "FIFO empty after reset"
        );

        check(
            fifo_full == 1'b0,
            "FIFO not full after reset"
        );


        // ========================================================
        // TEST 2 — SINGLE DATA ACQUISITION
        // ========================================================

        $display("");
        $display("TEST 2: SINGLE DATA ACQUISITION");

        @(negedge clk);
        source_enable = 1'b1;

        @(posedge clk);
        #1;

        @(negedge clk);
        source_enable = 1'b0;

        check(
            fifo_count == 1,
            "One sample stored in FIFO"
        );

        check(
            fifo_empty == 1'b0,
            "FIFO no longer empty"
        );


        // ========================================================
        // TEST 3 — DATA READ
        // ========================================================

        $display("");
        $display("TEST 3: DATA READ");

        @(negedge clk);
        consumer_read = 1'b1;

        @(posedge clk);
        #1;

        $display(
            "READ DEBUG: DATA=%0d VALID=%0b COUNT=%0d",
            data_out,
            data_valid,
            fifo_count
        );

        check(
            data_valid == 1'b1,
            "Data valid asserted during read"
        );

        check(
            data_out == 1,
            "First acquired sample = 1"
        );

        @(negedge clk);
        consumer_read = 1'b0;

        @(posedge clk);
        #1;

        check(
            fifo_count == 0,
            "FIFO empty after consuming sample"
        );


        // ========================================================
        // TEST 4 — BURST ACQUISITION
        // ========================================================

        $display("");
        $display("TEST 4: BURST ACQUISITION");

        reset_dut();

        @(negedge clk);
        source_enable = 1'b1;

        repeat (6) begin
            @(posedge clk);
            #1;
        end

        @(negedge clk);
        source_enable = 1'b0;

        @(posedge clk);
        #1;

        check(
            fifo_count == 6,
            "Six samples stored during burst"
        );


        // ========================================================
        // TEST 5 — FIFO DATA ORDER
        // ========================================================

        $display("");
        $display("TEST 5: FIFO DATA ORDER");

        expected_data = 1;

        @(negedge clk);
        consumer_read = 1'b1;

        repeat (6) begin

            @(posedge clk);
            #1;

            $display(
                "FIFO READ: EXPECTED=%0d ACTUAL=%0d VALID=%0b COUNT=%0d",
                expected_data,
                data_out,
                data_valid,
                fifo_count
            );

            check(
                data_valid == 1'b1,
                "FIFO read produces valid data"
            );

            check(
                data_out == expected_data,
                "FIFO data ordering correct"
            );

            expected_data = expected_data + 1;

        end

        @(negedge clk);
        consumer_read = 1'b0;

        @(posedge clk);
        #1;

        check(
            fifo_count == 0,
            "FIFO empty after burst consumption"
        );


        // ========================================================
        // TEST 6 — FIFO FULL
        // ========================================================

        $display("");
        $display("TEST 6: FIFO FULL CONDITION");

        reset_dut();

        @(negedge clk);
        source_enable = 1'b1;

        repeat (FIFO_DEPTH) begin
            @(posedge clk);
            #1;
        end

        @(negedge clk);
        source_enable = 1'b0;

        @(posedge clk);
        #1;

        check(
            fifo_count == FIFO_DEPTH,
            "FIFO reaches full capacity"
        );

        check(
            fifo_full == 1'b1,
            "FIFO FULL asserted"
        );


        // ========================================================
        // TEST 7 — OVERFLOW
        // ========================================================

        $display("");
        $display("TEST 7: OVERFLOW");

        @(negedge clk);
        source_enable = 1'b1;

        @(posedge clk);
        #1;

        check(
            overflow == 1'b1,
            "Overflow detected when FIFO is full"
        );

        check(
            fifo_count == FIFO_DEPTH,
            "FIFO count remains at maximum after overflow"
        );

        @(negedge clk);
        source_enable = 1'b0;


        // ========================================================
        // TEST 8 — UNDERFLOW
        // ========================================================

        $display("");
        $display("TEST 8: UNDERFLOW");

        reset_dut();

        @(negedge clk);
        consumer_read = 1'b1;

        @(posedge clk);
        #1;

        check(
            underflow == 1'b1,
            "Underflow detected when FIFO is empty"
        );

        check(
            fifo_count == 0,
            "FIFO remains empty after underflow"
        );

        @(negedge clk);
        consumer_read = 1'b0;


        // ========================================================
        // TEST 9 — PRODUCER FASTER THAN CONSUMER
        // ========================================================

        $display("");
        $display("TEST 9: PRODUCER FASTER THAN CONSUMER");

        reset_dut();

        @(negedge clk);
        source_enable = 1'b1;

        repeat (7) begin
            @(posedge clk);
            #1;
        end

        @(negedge clk);
        source_enable = 1'b0;

        @(posedge clk);
        #1;

        check(
            fifo_count == 7,
            "FIFO buffers seven incoming samples"
        );


        @(negedge clk);
        consumer_read = 1'b1;

        repeat (7) begin
            @(posedge clk);
            #1;
        end

        @(negedge clk);
        consumer_read = 1'b0;

        @(posedge clk);
        #1;

        check(
            fifo_count == 0,
            "Buffered samples successfully consumed"
        );


        // ========================================================
        // TEST 10 — SIMULTANEOUS READ/WRITE
        // ========================================================

        $display("");
        $display("TEST 10: SIMULTANEOUS READ/WRITE");

        reset_dut();

        @(negedge clk);
        source_enable = 1'b1;

        repeat (4) begin
            @(posedge clk);
            #1;
        end

        @(negedge clk);
        consumer_read = 1'b1;

        repeat (4) begin
            @(posedge clk);
            #1;
        end

        @(negedge clk);
        source_enable = 1'b0;
        consumer_read = 1'b0;

        @(posedge clk);
        #1;

        check(
            fifo_count == 4,
            "FIFO occupancy maintained during balanced operation"
        );


        // ========================================================
        // FINAL RESULT
        // ========================================================

        $display("");
        $display("================================================");
        $display("                 FINAL RESULT");
        $display("================================================");

        $display("TOTAL CHECKS  = %0d", checks);
        $display("PASSED CHECKS = %0d", passed);
        $display("FAILED CHECKS = %0d", failed);

        if (failed == 0)
            $display("OVERALL RESULT = PASS");
        else
            $display("OVERALL RESULT = FAIL");

        $display("================================================");

        $finish;

    end

endmodule