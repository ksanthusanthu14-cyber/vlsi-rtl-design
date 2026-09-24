`timescale 1ns/1ps

module fifo_tb;

    // ============================================================
    // SIGNALS
    // ============================================================

    reg clk;
    reg rst;

    reg        wr_en;
    reg        rd_en;
    reg [7:0]  wr_data;

    wire [7:0] rd_data;
    wire       full;
    wire       empty;


    // ============================================================
    // DUT
    // ============================================================

    fifo dut (
        .clk     (clk),
        .rst     (rst),
        .wr_en   (wr_en),
        .rd_en   (rd_en),
        .wr_data (wr_data),
        .rd_data (rd_data),
        .full    (full),
        .empty   (empty)
    );


    // ============================================================
    // UVM-STYLE COMPONENTS
    // ============================================================

    fifo_sequencer  sequencer;
    fifo_driver     driver;
    fifo_monitor    monitor;
    fifo_scoreboard scoreboard;

    fifo_transaction tr;


    // ============================================================
    // REFERENCE FIFO
    // ============================================================

    reg [7:0] reference_fifo [0:1023];

    integer ref_wr_ptr;
    integer ref_rd_ptr;
    integer ref_count;


    // ============================================================
    // TEMPORARY VARIABLES
    // ============================================================

    integer i;

    reg       accept_write;
    reg       accept_read;

    reg [7:0] expected_read;

    reg       expected_full;
    reg       expected_empty;

    // PRE-OPERATION FLAGS
    reg       pre_full;
    reg       pre_empty;


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin


        // ========================================================
        // VCD
        // ========================================================

        $dumpfile("uvm_fifo.vcd");
        $dumpvars(0, fifo_tb);


        // ========================================================
        // INITIALIZATION
        // ========================================================

        rst     = 1'b1;

        wr_en   = 1'b0;
        rd_en   = 1'b0;
        wr_data = 8'h00;

        ref_wr_ptr = 0;
        ref_rd_ptr = 0;
        ref_count  = 0;


        // ========================================================
        // RESET
        // ========================================================

        repeat (2)
            @(posedge clk);

        #1;

        rst = 1'b0;


        // ========================================================
        // CREATE COMPONENTS
        // ========================================================

        sequencer  = new;
        driver     = new;
        monitor    = new;
        scoreboard = new;


        $display("");
        $display("======================================");
        $display("UVM-STYLE FIFO TEST START");
        $display("======================================");


        // ========================================================
        // DIRECTED TEST 1
        // FIFO FILL
        // ========================================================

        $display("");
        $display("----- DIRECTED TEST: FIFO FILL -----");


        for (i = 0; i < 8; i = i + 1) begin

            wr_en   = 1'b1;
            rd_en   = 1'b0;
            wr_data = 8'h10 + i;


            driver.drive(
                wr_en,
                rd_en,
                wr_data
            );


            @(posedge clk);

            #1;


            // Reference model update

            reference_fifo[ref_wr_ptr] = wr_data;

            ref_wr_ptr = ref_wr_ptr + 1;

            if (ref_wr_ptr == 1024)
                ref_wr_ptr = 0;

            ref_count = ref_count + 1;


            // Expected flags

            expected_full  = (ref_count == 8);
            expected_empty = (ref_count == 0);


            scoreboard.check_status(
                full,
                empty,
                expected_full,
                expected_empty
            );


            monitor.sample(
                wr_en,
                rd_en,
                wr_data,
                rd_data,
                full,
                empty
            );

        end


        // ========================================================
        // DIRECTED TEST 2
        // OVERFLOW
        // ========================================================

        $display("");
        $display("----- DIRECTED TEST: OVERFLOW -----");


        wr_en   = 1'b1;
        rd_en   = 1'b0;
        wr_data = 8'hEE;


        driver.drive(
            wr_en,
            rd_en,
            wr_data
        );


        @(posedge clk);

        #1;


        // FIFO was full BEFORE operation.
        scoreboard.check_overflow(1'b1);


        expected_full  = 1'b1;
        expected_empty = 1'b0;


        scoreboard.check_status(
            full,
            empty,
            expected_full,
            expected_empty
        );


        monitor.sample(
            wr_en,
            rd_en,
            wr_data,
            rd_data,
            full,
            empty
        );


        // ========================================================
        // DIRECTED TEST 3
        // FIFO DRAIN
        // ========================================================

        $display("");
        $display("----- DIRECTED TEST: FIFO DRAIN -----");


        for (i = 0; i < 8; i = i + 1) begin


            expected_read = reference_fifo[ref_rd_ptr];


            wr_en = 1'b0;
            rd_en = 1'b1;


            driver.drive(
                wr_en,
                rd_en,
                wr_data
            );


            @(posedge clk);

            #1;


            scoreboard.check_read(
                rd_data,
                expected_read
            );


            // Reference model update

            ref_rd_ptr = ref_rd_ptr + 1;

            if (ref_rd_ptr == 1024)
                ref_rd_ptr = 0;

            ref_count = ref_count - 1;


            expected_full  = (ref_count == 8);
            expected_empty = (ref_count == 0);


            scoreboard.check_status(
                full,
                empty,
                expected_full,
                expected_empty
            );


            monitor.sample(
                wr_en,
                rd_en,
                wr_data,
                rd_data,
                full,
                empty
            );

        end


        // ========================================================
        // DIRECTED TEST 4
        // UNDERFLOW
        // ========================================================

        $display("");
        $display("----- DIRECTED TEST: UNDERFLOW -----");


        wr_en = 1'b0;
        rd_en = 1'b1;


        driver.drive(
            wr_en,
            rd_en,
            wr_data
        );


        @(posedge clk);

        #1;


        // FIFO was empty BEFORE operation.
        scoreboard.check_underflow(1'b1);


        expected_full  = 1'b0;
        expected_empty = 1'b1;


        scoreboard.check_status(
            full,
            empty,
            expected_full,
            expected_empty
        );


        monitor.sample(
            wr_en,
            rd_en,
            wr_data,
            rd_data,
            full,
            empty
        );


        // ========================================================
        // RANDOMIZED TEST
        // ========================================================

        $display("");
        $display("----- RANDOMIZED FIFO TEST -----");


        for (i = 0; i < 100; i = i + 1) begin


            // ----------------------------------------------------
            // GENERATE TRANSACTION
            // ----------------------------------------------------

            sequencer.get_next_transaction(tr);


            // ----------------------------------------------------
            // CAPTURE PRE-OPERATION FIFO STATE
            // ----------------------------------------------------

            pre_full  = (ref_count == 8);
            pre_empty = (ref_count == 0);


            // ----------------------------------------------------
            // DETERMINE ACCEPTANCE
            // ----------------------------------------------------

            accept_write =
                tr.write_en &&
                !pre_full;


            accept_read =
                tr.read_en &&
                !pre_empty;


            // ----------------------------------------------------
            // CAPTURE EXPECTED READ DATA
            // ----------------------------------------------------

            if (accept_read)
                expected_read =
                    reference_fifo[ref_rd_ptr];


            // ----------------------------------------------------
            // DRIVER
            // ----------------------------------------------------

            driver.drive(
                tr.write_en,
                tr.read_en,
                tr.write_data
            );


            // ----------------------------------------------------
            // DRIVE DUT
            // ----------------------------------------------------

            wr_en   = tr.write_en;
            rd_en   = tr.read_en;
            wr_data = tr.write_data;


            // ----------------------------------------------------
            // CLOCK
            // ----------------------------------------------------

            @(posedge clk);

            #1;


            // ====================================================
            // WRITE
            // ====================================================

            if (tr.write_en) begin

                if (accept_write) begin

                    reference_fifo[ref_wr_ptr] =
                        tr.write_data;


                    ref_wr_ptr = ref_wr_ptr + 1;

                    if (ref_wr_ptr == 1024)
                        ref_wr_ptr = 0;

                end
                else begin

                    // IMPORTANT:
                    // Check PREVIOUS full state.
                    // Do NOT check current full after clock.

                    scoreboard.check_overflow(
                        pre_full
                    );

                end

            end


            // ====================================================
            // READ
            // ====================================================

            if (tr.read_en) begin

                if (accept_read) begin

                    scoreboard.check_read(
                        rd_data,
                        expected_read
                    );


                    ref_rd_ptr = ref_rd_ptr + 1;

                    if (ref_rd_ptr == 1024)
                        ref_rd_ptr = 0;

                end
                else begin

                    // IMPORTANT:
                    // Check PREVIOUS empty state.
                    // Do NOT check current empty after clock.

                    scoreboard.check_underflow(
                        pre_empty
                    );

                end

            end


            // ====================================================
            // UPDATE REFERENCE OCCUPANCY
            // ====================================================

            if (accept_write && !accept_read) begin

                ref_count = ref_count + 1;

            end
            else if (!accept_write && accept_read) begin

                ref_count = ref_count - 1;

            end
            else begin

                // Both accepted:
                // occupancy unchanged.

                // Both rejected:
                // occupancy unchanged.

                ref_count = ref_count;

            end


            // ====================================================
            // EXPECTED POST-OPERATION FLAGS
            // ====================================================

            expected_full  = (ref_count == 8);
            expected_empty = (ref_count == 0);


            // ====================================================
            // POST-OPERATION STATUS CHECK
            // ====================================================

            scoreboard.check_status(
                full,
                empty,
                expected_full,
                expected_empty
            );


            // ====================================================
            // MONITOR
            // ====================================================

            monitor.sample(
                wr_en,
                rd_en,
                wr_data,
                rd_data,
                full,
                empty
            );


            // ====================================================
            // CLEAR
            // ====================================================

            wr_en = 1'b0;
            rd_en = 1'b0;

        end


        // ========================================================
        // FINAL REPORT
        // ========================================================

        scoreboard.report;


        // ========================================================
        // COMPLETE
        // ========================================================

        #20;

        $display("");
        $display("======================================");
        $display("UVM-STYLE FIFO TEST COMPLETE");
        $display("======================================");


        $finish;

    end

endmodule