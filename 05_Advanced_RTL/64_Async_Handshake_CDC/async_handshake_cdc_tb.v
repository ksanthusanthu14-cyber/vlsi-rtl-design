`timescale 1ns/1ps

module async_handshake_cdc_tb;

    // =========================================================
    // SIGNALS
    // =========================================================

    reg src_clk;
    reg dest_clk;
    reg rst;

    reg src_req;

    wire dest_event;
    wire src_busy;

    integer errors;
    integer event_count;


    // =========================================================
    // DUT
    // =========================================================

    async_handshake_cdc dut (

        .src_clk(src_clk),
        .dest_clk(dest_clk),
        .rst(rst),

        .src_req(src_req),

        .dest_event(dest_event),
        .src_busy(src_busy)

    );


    // =========================================================
    // SOURCE CLOCK
    // 10 ns PERIOD
    // =========================================================

    initial begin

        src_clk = 1'b0;

        forever #5 src_clk = ~src_clk;

    end


    // =========================================================
    // DESTINATION CLOCK
    // 14 ns PERIOD
    // =========================================================

    initial begin

        dest_clk = 1'b0;

        forever #7 dest_clk = ~dest_clk;

    end


    // =========================================================
    // VCD
    // =========================================================

    initial begin

        $dumpfile("async_handshake_cdc_tb.vcd");

        $dumpvars(0, async_handshake_cdc_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | RESET=%b | SRC_REQ=%b | REQ_REG=%b | REQ_FF1=%b | REQ_FF2=%b | DEST_EVENT=%b | ACK=%b | ACK_FF1=%b | ACK_FF2=%b | BUSY=%b",
            $time,
            rst,
            src_req,
            dut.req_reg,
            dut.req_sync1,
            dut.req_sync2,
            dest_event,
            dut.ack_reg,
            dut.ack_sync1,
            dut.ack_sync2,
            src_busy
        );

    end


    // =========================================================
    // COUNT DESTINATION EVENTS
    // =========================================================

    always @(negedge dest_clk) begin

        if (dest_event)
            event_count = event_count + 1;

    end


    // =========================================================
    // TEST SEQUENCE
    // =========================================================

    initial begin

        errors = 0;
        event_count = 0;

        // -----------------------------------------------------
        // INITIAL CONDITIONS
        // -----------------------------------------------------

        rst = 1'b1;

        src_req = 1'b0;


        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        #20;

        rst = 1'b0;


        // =====================================================
        // TEST 1: FIRST REQUEST
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 1: FIRST HANDSHAKE");
        $display("========================================");

        // Generate source request
        #3;

        src_req = 1'b1;

        @(posedge src_clk);
        #1;

        src_req = 1'b0;


        // Source should become busy
        if (src_busy !== 1'b1) begin

            $display("FAIL: TEST 1 | SOURCE DID NOT BECOME BUSY");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 1 | SOURCE BUSY");

        end


        // Wait for destination event
        #50;


        if (event_count != 1) begin

            $display(
                "FAIL: TEST 1 | EXPECTED EVENT=1 | RECEIVED=%0d",
                event_count
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 1 | DESTINATION RECEIVED REQUEST");

        end


        // Wait for ACK to return
        #50;


        if (src_busy !== 1'b0) begin

            $display("FAIL: TEST 1 | BUSY DID NOT CLEAR");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 1 | ACK RECEIVED | BUSY CLEARED");

        end


        // =====================================================
        // TEST 2: SECOND REQUEST
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: SECOND HANDSHAKE");
        $display("========================================");

        #10;

        src_req = 1'b1;

        @(posedge src_clk);
        #1;

        src_req = 1'b0;


        #60;


        if (event_count != 2) begin

            $display(
                "FAIL: TEST 2 | EXPECTED EVENT=2 | RECEIVED=%0d",
                event_count
            );

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | SECOND REQUEST RECEIVED");

        end


        #50;


        if (src_busy !== 1'b0) begin

            $display("FAIL: TEST 2 | BUSY DID NOT CLEAR");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | SECOND ACK RECEIVED");

        end


        // =====================================================
        // TEST 3: REQUEST WHILE BUSY
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: REQUEST WHILE BUSY");
        $display("========================================");

        src_req = 1'b1;

        @(posedge src_clk);
        #1;

        src_req = 1'b0;


        // Immediately attempt another request
        #2;

        src_req = 1'b1;

        @(posedge src_clk);
        #1;

        src_req = 1'b0;


        #70;


        // Only one destination event should have been generated
        // by this transaction sequence.

        if (event_count != 3) begin

            $display(
                "FAIL: TEST 3 | EXPECTED EVENT=3 | RECEIVED=%0d",
                event_count
            );

            errors = errors + 1;

        end

        else begin

            $display(
                "PASS: TEST 3 | BUSY PREVENTED DUPLICATE REQUEST"
            );

        end


        #60;


        // =====================================================
        // FINAL RESULT
        // =====================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin

            $display("ALL ASYNC HANDSHAKE CDC TESTS PASSED");

        end

        else begin

            $display("ASYNC HANDSHAKE CDC TEST FAILED");

            $display("ERRORS = %0d", errors);

        end

        $display("========================================");

        $finish;

    end

endmodule