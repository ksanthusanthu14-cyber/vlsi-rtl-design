`timescale 1ns/1ps

module uart_coverage_tb;

    parameter CLKS_PER_BIT = 4;

    // ============================================================
    // CLOCK / RESET
    // ============================================================

    reg clk;
    reg rst;

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // UART TX
    // ============================================================

    reg [7:0] tx_data;
    reg       tx_start;

    wire tx;
    wire tx_busy;
    wire tx_done;

    // ============================================================
    // UART RX
    // ============================================================

    wire [7:0] rx_data;
    wire       rx_valid;
    wire       rx_error;

    // ============================================================
    // MANUAL RX ERROR INJECTION
    // ============================================================

    reg rx_error_test;
    reg rx_manual_line;

    wire rx_line;

    assign rx_line =
        rx_error_test ? rx_manual_line : tx;

    // ============================================================
    // UART TX INSTANCE
    // ============================================================

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uut_tx (
        .clk      (clk),
        .rst      (rst),
        .tx_start (tx_start),
        .tx_data  (tx_data),
        .tx        (tx),
        .tx_busy  (tx_busy),
        .tx_done  (tx_done)
    );

    // ============================================================
    // UART RX INSTANCE
    // ============================================================

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) uut_rx (
        .clk      (clk),
        .rst       (rst),
        .rx        (rx_line),
        .rx_data   (rx_data),
        .rx_valid  (rx_valid),
        .rx_error  (rx_error)
    );

    // ============================================================
    // TEST COUNTERS
    // ============================================================

    integer total_tests;
    integer passed_tests;
    integer failed_tests;

    integer tx_done_hits;
    integer rx_valid_hits;
    integer rx_error_hits;

    integer rx_wait_cycles;

    integer i;
    integer j;

    reg [7:0] random_byte;

    // ============================================================
    // DATA CLASS COVERAGE
    //
    // 0 = ZERO
    // 1 = LOW
    // 2 = NORMAL
    // 3 = HIGH
    // 4 = MAX
    // 5 = ALTERNATING
    // ============================================================

    integer data_class_hits [0:5];

    // ============================================================
    // SPECIAL PATTERN COVERAGE
    //
    // 0 = 00
    // 1 = FF
    // 2 = AA
    // 3 = 55
    // ============================================================

    integer special_pattern_hits [0:3];

    // ============================================================
    // RX RESULT COVERAGE
    //
    // 0 = VALID
    // 1 = ERROR
    // ============================================================

    integer rx_result_hits [0:1];

    // ============================================================
    // CROSS COVERAGE
    //
    // DATA CLASS x RX RESULT
    //
    // 6 x 2 = 12 BINS
    // ============================================================

    integer cross_hits [0:5][0:1];

    // ============================================================
    // COVERAGE SUMMARY VARIABLES
    // ============================================================

    integer data_bins_hit;
    integer special_bins_hit;
    integer rx_bins_hit;
    integer cross_bins_hit;

    integer total_coverage_bins;
    integer coverage_bins_hit;
    integer coverage_percent;

    // ============================================================
    // FUNCTION: DATA CLASSIFICATION
    // ============================================================

    function integer get_data_class;

        input [7:0] data;

        begin

            if (data == 8'h00)
                get_data_class = 0;

            else if (data == 8'hFF)
                get_data_class = 4;

            else if ((data == 8'hAA) ||
                     (data == 8'h55))
                get_data_class = 5;

            else if (data <= 8'h3F)
                get_data_class = 1;

            else if (data >= 8'hC0)
                get_data_class = 3;

            else
                get_data_class = 2;

        end

    endfunction

    // ============================================================
    // TASK: WAIT FOR RX RESULT
    // ============================================================

    task wait_for_rx_result;

        begin

            rx_wait_cycles = 0;

            while ((!rx_valid) &&
                   (!rx_error) &&
                   (rx_wait_cycles < 100)) begin

                @(posedge clk);
                #1;

                rx_wait_cycles =
                    rx_wait_cycles + 1;

            end

        end

    endtask

    // ============================================================
    // TASK: UPDATE COVERAGE
    // ============================================================

    task update_coverage;

        input [7:0] data;

        integer cls;

        begin

            cls = get_data_class(data);

            // ----------------------------------------------------
            // DATA CLASS
            // ----------------------------------------------------

            data_class_hits[cls] =
                data_class_hits[cls] + 1;

            // ----------------------------------------------------
            // SPECIAL PATTERNS
            // ----------------------------------------------------

            if (data == 8'h00)
                special_pattern_hits[0] =
                    special_pattern_hits[0] + 1;

            if (data == 8'hFF)
                special_pattern_hits[1] =
                    special_pattern_hits[1] + 1;

            if (data == 8'hAA)
                special_pattern_hits[2] =
                    special_pattern_hits[2] + 1;

            if (data == 8'h55)
                special_pattern_hits[3] =
                    special_pattern_hits[3] + 1;

            // ----------------------------------------------------
            // VALID RESULT
            // ----------------------------------------------------

            if (rx_valid) begin

                rx_result_hits[0] =
                    rx_result_hits[0] + 1;

                cross_hits[cls][0] =
                    cross_hits[cls][0] + 1;

            end

            // ----------------------------------------------------
            // ERROR RESULT
            // ----------------------------------------------------

            if (rx_error) begin

                rx_result_hits[1] =
                    rx_result_hits[1] + 1;

                cross_hits[cls][1] =
                    cross_hits[cls][1] + 1;

            end

        end

    endtask

    // ============================================================
    // TASK: NORMAL UART BYTE
    // ============================================================

    task send_byte;

        input [7:0] data;

        integer timeout;

        begin

            total_tests =
                total_tests + 1;

            // ----------------------------------------------------
            // WAIT FOR TX IDLE
            // ----------------------------------------------------

            timeout = 0;

            while (tx_busy &&
                   (timeout < 100)) begin

                @(posedge clk);
                #1;

                timeout =
                    timeout + 1;

            end

            // ----------------------------------------------------
            // START TRANSMISSION
            // ----------------------------------------------------

            @(posedge clk);
            #1;

            tx_data  = data;
            tx_start = 1'b1;

            @(posedge clk);
            #1;

            tx_start = 1'b0;

            // ----------------------------------------------------
            // WAIT FOR RX
            // ----------------------------------------------------

            wait_for_rx_result;

            // ----------------------------------------------------
            // CHECK RECEIVED BYTE
            // ----------------------------------------------------

            if (rx_valid &&
                !rx_error &&
                (rx_data == data)) begin

                passed_tests =
                    passed_tests + 1;

                $display(
                    "PASS: TX=%02h RX=%02h VALID=%b ERROR=%b",
                    data,
                    rx_data,
                    rx_valid,
                    rx_error
                );

            end
            else begin

                failed_tests =
                    failed_tests + 1;

                $display(
                    "FAIL: TX=%02h RX=%02h VALID=%b ERROR=%b",
                    data,
                    rx_data,
                    rx_valid,
                    rx_error
                );

            end

            // ----------------------------------------------------
            // COVERAGE
            // ----------------------------------------------------

            update_coverage(data);

            if (rx_valid)
                rx_valid_hits =
                    rx_valid_hits + 1;

            if (rx_error)
                rx_error_hits =
                    rx_error_hits + 1;

            // ----------------------------------------------------
            // WAIT
            // ----------------------------------------------------

            @(posedge clk);
            #1;

            timeout = 0;

            while (tx_busy &&
                   (timeout < 100)) begin

                @(posedge clk);
                #1;

                timeout =
                    timeout + 1;

            end

            if (tx_done)
                tx_done_hits =
                    tx_done_hits + 1;

        end

    endtask

    // ============================================================
    // TASK: ERROR FRAME
    //
    // IMPORTANT:
    //
    // For this UART RX implementation:
    //
    // IDLE detects START.
    //
    // START state takes two clocks with
    // CLKS_PER_BIT = 4.
    //
    // DATA state then samples every four clocks.
    //
    // Therefore the first DATA bit must be placed after
    // the receiver enters DATA.
    //
    // START LOW = 3 CLOCKS
    //
    // Then:
    //
    // DATA[0] ... DATA[7]
    //
    // Finally:
    //
    // STOP = 0  <-- intentionally invalid
    // ============================================================

    task send_error_frame;

        input [7:0] data;

        integer timeout;

        begin

            total_tests =
                total_tests + 1;

            // ====================================================
            // ENABLE MANUAL RX LINE
            // ====================================================

            rx_error_test  = 1'b1;
            rx_manual_line = 1'b1;

            // ====================================================
            // RESET RECEIVER
            // ====================================================

            rst = 1'b1;

            repeat (3)
                @(posedge clk);

            #1;

            rst = 1'b0;

            // ====================================================
            // IDLE
            // ====================================================

            rx_manual_line = 1'b1;

            repeat (2)
                @(posedge clk);

            #1;

            // ====================================================
            // START BIT
            // ====================================================

            rx_manual_line = 1'b0;

            // ----------------------------------------------------
            // IMPORTANT:
            //
            // Use 3 clocks, NOT 6.
            //
            // This aligns with the actual uart_rx FSM.
            // ----------------------------------------------------

            repeat (3)
                @(posedge clk);

            #1;

            // ====================================================
            // DATA BITS
            //
            // UART sends LSB FIRST.
            // ====================================================

            for (j = 0; j < 8; j = j + 1) begin

                rx_manual_line = data[j];

                repeat (CLKS_PER_BIT)
                    @(posedge clk);

                #1;

            end

            // ====================================================
            // INVALID STOP BIT
            //
            // Correct UART STOP = 1
            //
            // We deliberately send:
            //
            // STOP = 0
            //
            // This must produce rx_error = 1.
            // ====================================================

            rx_manual_line = 1'b0;

            repeat (CLKS_PER_BIT)
                @(posedge clk);

            #1;

            // ====================================================
            // RETURN TO IDLE
            // ====================================================

            rx_manual_line = 1'b1;

            // ====================================================
            // WAIT FOR RX ERROR
            // ====================================================

            timeout = 0;

            while ((!rx_error) &&
                   (!rx_valid) &&
                   (timeout < 20)) begin

                @(posedge clk);
                #1;

                timeout =
                    timeout + 1;

            end

            // ====================================================
            // CHECK RESULT
            // ====================================================

            if (rx_error) begin

                passed_tests =
                    passed_tests + 1;

                $display(
                    "PASS ERROR TEST: DATA=%02h RX=%02h VALID=%b ERROR=%b",
                    data,
                    rx_data,
                    rx_valid,
                    rx_error
                );

            end
            else begin

                failed_tests =
                    failed_tests + 1;

                $display(
                    "FAIL ERROR TEST: DATA=%02h RX=%02h VALID=%b ERROR=%b",
                    data,
                    rx_data,
                    rx_valid,
                    rx_error
                );

            end

            // ====================================================
            // UPDATE COVERAGE
            // ====================================================

            update_coverage(data);

            if (rx_valid)
                rx_valid_hits =
                    rx_valid_hits + 1;

            if (rx_error)
                rx_error_hits =
                    rx_error_hits + 1;

            // ====================================================
            // RETURN TO NORMAL RX
            // ====================================================

            rx_manual_line = 1'b1;

            repeat (3)
                @(posedge clk);

            #1;

            rx_error_test = 1'b0;

            repeat (2)
                @(posedge clk);

        end

    endtask

    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // ========================================================
        // INITIALIZATION
        // ========================================================

        total_tests   = 0;
        passed_tests  = 0;
        failed_tests  = 0;

        tx_done_hits  = 0;
        rx_valid_hits = 0;
        rx_error_hits = 0;

        rx_wait_cycles = 0;

        tx_data  = 8'h00;
        tx_start = 1'b0;

        rx_error_test  = 1'b0;
        rx_manual_line = 1'b1;

        // ========================================================
        // INITIALIZE COVERAGE
        // ========================================================

        for (i = 0; i < 6; i = i + 1)
            data_class_hits[i] = 0;

        for (i = 0; i < 4; i = i + 1)
            special_pattern_hits[i] = 0;

        for (i = 0; i < 2; i = i + 1)
            rx_result_hits[i] = 0;

        for (i = 0; i < 6; i = i + 1) begin

            cross_hits[i][0] = 0;
            cross_hits[i][1] = 0;

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
        $display("UART FUNCTIONAL COVERAGE VERIFICATION");
        $display("==============================================");
        $display("");

        // ========================================================
        // DIRECTED TESTS
        // ========================================================

        $display("DIRECTED TESTS");
        $display("----------------------------------------------");

        send_byte(8'h00);
        send_byte(8'hFF);
        send_byte(8'hAA);
        send_byte(8'h55);
        send_byte(8'h01);
        send_byte(8'h02);
        send_byte(8'h7F);
        send_byte(8'h80);
        send_byte(8'h3C);
        send_byte(8'hC3);

        // ========================================================
        // RANDOMIZED TESTS
        // ========================================================

        $display("");
        $display("RANDOMIZED TESTS");
        $display("----------------------------------------------");

        for (i = 0; i < 100; i = i + 1) begin

            random_byte = $random;

            send_byte(random_byte);

        end

        // ========================================================
        // ERROR INJECTION
        // ========================================================

        $display("");
        $display("RX ERROR INJECTION TESTS");
        $display("----------------------------------------------");

        send_error_frame(8'h00);
        send_error_frame(8'h01);
        send_error_frame(8'h55);
        send_error_frame(8'h80);
        send_error_frame(8'hC3);
        send_error_frame(8'hFF);

        // ========================================================
        // CALCULATE COVERAGE
        // ========================================================

        data_bins_hit     = 0;
        special_bins_hit = 0;
        rx_bins_hit       = 0;
        cross_bins_hit    = 0;

        // ========================================================
        // DATA CLASS BINS
        // ========================================================

        for (i = 0; i < 6; i = i + 1) begin

            if (data_class_hits[i] > 0)
                data_bins_hit =
                    data_bins_hit + 1;

        end

        // ========================================================
        // SPECIAL PATTERN BINS
        // ========================================================

        for (i = 0; i < 4; i = i + 1) begin

            if (special_pattern_hits[i] > 0)
                special_bins_hit =
                    special_bins_hit + 1;

        end

        // ========================================================
        // RX RESULT BINS
        // ========================================================

        for (i = 0; i < 2; i = i + 1) begin

            if (rx_result_hits[i] > 0)
                rx_bins_hit =
                    rx_bins_hit + 1;

        end

        // ========================================================
        // CROSS BINS
        // ========================================================

        for (i = 0; i < 6; i = i + 1) begin

            if (cross_hits[i][0] > 0)
                cross_bins_hit =
                    cross_bins_hit + 1;

            if (cross_hits[i][1] > 0)
                cross_bins_hit =
                    cross_bins_hit + 1;

        end

        // ========================================================
        // TOTAL COVERAGE
        // ========================================================

        total_coverage_bins = 24;

        coverage_bins_hit =
            data_bins_hit +
            special_bins_hit +
            rx_bins_hit +
            cross_bins_hit;

        coverage_percent =
            (coverage_bins_hit * 100) /
            total_coverage_bins;

        // ========================================================
        // SUMMARY
        // ========================================================

        $display("");
        $display("==============================================");
        $display("FUNCTIONAL COVERAGE SUMMARY");
        $display("==============================================");

        $display("");

        $display(
            "TOTAL TESTS        = %0d",
            total_tests
        );

        $display(
            "PASSED TESTS       = %0d",
            passed_tests
        );

        $display(
            "FAILED TESTS       = %0d",
            failed_tests
        );

        $display("");

        $display(
            "TX DONE HITS       = %0d",
            tx_done_hits
        );

        $display(
            "RX VALID HITS      = %0d",
            rx_valid_hits
        );

        $display(
            "RX ERROR HITS      = %0d",
            rx_error_hits
        );

        // ========================================================
        // DATA CLASS COVERAGE
        // ========================================================

        $display("");
        $display("DATA CLASS COVERAGE");
        $display("----------------------------------------------");

        $display(
            "ZERO         = %0d",
            data_class_hits[0]
        );

        $display(
            "LOW          = %0d",
            data_class_hits[1]
        );

        $display(
            "NORMAL       = %0d",
            data_class_hits[2]
        );

        $display(
            "HIGH         = %0d",
            data_class_hits[3]
        );

        $display(
            "MAX          = %0d",
            data_class_hits[4]
        );

        $display(
            "ALTERNATING  = %0d",
            data_class_hits[5]
        );

        // ========================================================
        // SPECIAL PATTERN COVERAGE
        // ========================================================

        $display("");
        $display("SPECIAL PATTERN COVERAGE");
        $display("----------------------------------------------");

        $display(
            "0x00 = %0d",
            special_pattern_hits[0]
        );

        $display(
            "0xFF = %0d",
            special_pattern_hits[1]
        );

        $display(
            "0xAA = %0d",
            special_pattern_hits[2]
        );

        $display(
            "0x55 = %0d",
            special_pattern_hits[3]
        );

        // ========================================================
        // RX RESULT COVERAGE
        // ========================================================

        $display("");
        $display("RX RESULT COVERAGE");
        $display("----------------------------------------------");

        $display(
            "VALID = %0d",
            rx_result_hits[0]
        );

        $display(
            "ERROR = %0d",
            rx_result_hits[1]
        );

        // ========================================================
        // CROSS COVERAGE
        // ========================================================

        $display("");
        $display("DATA CLASS x RX RESULT COVERAGE");
        $display("----------------------------------------------");

        $display(
            "             VALID   ERROR"
        );

        $display(
            "ZERO         %5d   %5d",
            cross_hits[0][0],
            cross_hits[0][1]
        );

        $display(
            "LOW          %5d   %5d",
            cross_hits[1][0],
            cross_hits[1][1]
        );

        $display(
            "NORMAL       %5d   %5d",
            cross_hits[2][0],
            cross_hits[2][1]
        );

        $display(
            "HIGH         %5d   %5d",
            cross_hits[3][0],
            cross_hits[3][1]
        );

        $display(
            "MAX          %5d   %5d",
            cross_hits[4][0],
            cross_hits[4][1]
        );

        $display(
            "ALTERNATING  %5d   %5d",
            cross_hits[5][0],
            cross_hits[5][1]
        );

        // ========================================================
        // COVERAGE TOTALS
        // ========================================================

        $display("");
        $display("==============================================");

        $display(
            "DATA CLASS BINS HIT       = %0d / 6",
            data_bins_hit
        );

        $display(
            "SPECIAL PATTERN BINS HIT  = %0d / 4",
            special_bins_hit
        );

        $display(
            "RX RESULT BINS HIT        = %0d / 2",
            rx_bins_hit
        );

        $display(
            "CROSS BINS HIT            = %0d / 12",
            cross_bins_hit
        );

        $display("");

        $display(
            "TOTAL COVERAGE BINS       = %0d / %0d",
            coverage_bins_hit,
            total_coverage_bins
        );

        $display(
            "FUNCTIONAL COVERAGE       = %0d%%",
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
            "UART FUNCTIONAL COVERAGE VERIFICATION COMPLETE"
        );

        $display("==============================================");

        $finish;

    end

endmodule