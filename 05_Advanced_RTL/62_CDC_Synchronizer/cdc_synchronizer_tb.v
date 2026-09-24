`timescale 1ns/1ps

module cdc_synchronizer_tb;

    // =========================================================
    // TESTBENCH SIGNALS
    // =========================================================

    reg dest_clk;
    reg rst;

    reg async_signal;

    wire sync_out;

    integer errors;


    // =========================================================
    // DUT
    // =========================================================

    cdc_synchronizer dut (

        .dest_clk(dest_clk),
        .rst(rst),

        .async_signal(async_signal),

        .sync_out(sync_out)

    );


    // =========================================================
    // DESTINATION CLOCK
    // =========================================================

    initial begin

        dest_clk = 1'b0;

        forever #5 dest_clk = ~dest_clk;

    end


    // =========================================================
    // VCD
    // =========================================================

    initial begin

        $dumpfile("cdc_synchronizer_tb.vcd");

        $dumpvars(0, cdc_synchronizer_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | RESET=%b | ASYNC=%b | FF1=%b | SYNC_OUT=%b",
            $time,
            rst,
            async_signal,
            dut.sync_ff1,
            sync_out
        );

    end


    // =========================================================
    // TEST SEQUENCE
    // =========================================================

    initial begin

        errors = 0;

        // -----------------------------------------------------
        // INITIAL CONDITIONS
        // -----------------------------------------------------

        rst = 1'b1;

        async_signal = 1'b0;


        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        #20;

        rst = 1'b0;


        // =====================================================
        // TEST 1: RESET / INITIAL LOW
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 1: INITIAL LOW");
        $display("========================================");

        repeat (2) begin
            @(posedge dest_clk);
            #1;
        end

        if (sync_out !== 1'b0) begin

            $display("FAIL: TEST 1");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 1 | OUTPUT LOW");

        end


        // =====================================================
        // TEST 2: ASYNC RISING TRANSITION
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: ASYNC RISING TRANSITION");
        $display("========================================");

        // Deliberately change away from the clock edge
        #3;

        async_signal = 1'b1;

        // First destination clock:
        // FF1 should capture 1
        @(posedge dest_clk);
        #1;

        if (dut.sync_ff1 !== 1'b1 ||
            sync_out !== 1'b0) begin

            $display("FAIL: TEST 2 | FIRST STAGE");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | FIRST STAGE");

        end

        // Second destination clock:
        // FF2/output should capture FF1
        @(posedge dest_clk);
        #1;

        if (sync_out !== 1'b1) begin

            $display("FAIL: TEST 2 | SYNCHRONIZED OUTPUT");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 2 | SYNCHRONIZED OUTPUT HIGH");

        end


        // =====================================================
        // TEST 3: STABLE HIGH
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: STABLE HIGH");
        $display("========================================");

        repeat (3) begin
            @(posedge dest_clk);
            #1;
        end

        if (sync_out !== 1'b1) begin

            $display("FAIL: TEST 3");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 3 | STABLE HIGH");

        end


        // =====================================================
        // TEST 4: ASYNC FALLING TRANSITION
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 4: ASYNC FALLING TRANSITION");
        $display("========================================");

        #2;

        async_signal = 1'b0;

        // First destination clock
        @(posedge dest_clk);
        #1;

        if (dut.sync_ff1 !== 1'b0 ||
            sync_out !== 1'b1) begin

            $display("FAIL: TEST 4 | FIRST STAGE");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 4 | FIRST STAGE");

        end

        // Second destination clock
        @(posedge dest_clk);
        #1;

        if (sync_out !== 1'b0) begin

            $display("FAIL: TEST 4 | SYNCHRONIZED OUTPUT");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 4 | SYNCHRONIZED OUTPUT LOW");

        end


        // =====================================================
        // TEST 5: MULTIPLE ASYNC TRANSITIONS
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 5: MULTIPLE ASYNC TRANSITIONS");
        $display("========================================");

        async_signal = 1'b1;

        @(posedge dest_clk);
        #1;

        @(posedge dest_clk);
        #1;

        if (sync_out !== 1'b1) begin

            $display("FAIL: TEST 5 | HIGH");

            errors = errors + 1;

        end

        async_signal = 1'b0;

        @(posedge dest_clk);
        #1;

        @(posedge dest_clk);
        #1;

        if (sync_out !== 1'b0) begin

            $display("FAIL: TEST 5 | LOW");

            errors = errors + 1;

        end

        else begin

            $display("PASS: TEST 5 | MULTIPLE TRANSITIONS");

        end


        // =====================================================
        // FINAL RESULT
        // =====================================================

        $display("");
        $display("========================================");

        if (errors == 0) begin

            $display("ALL CDC SYNCHRONIZER TESTS PASSED");

        end

        else begin

            $display("CDC SYNCHRONIZER TEST FAILED");

            $display("ERRORS = %0d", errors);

        end

        $display("========================================");

        $finish;

    end

endmodule