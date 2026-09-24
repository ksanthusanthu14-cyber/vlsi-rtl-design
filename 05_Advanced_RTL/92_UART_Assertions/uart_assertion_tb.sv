`timescale 1ns/1ps

module uart_assertion_tb;

    localparam int CLKS_PER_BIT = 4;

    logic clk;
    logic rst;

    logic start;
    logic [7:0] tx_data;

    logic tx;
    logic tx_busy;
    logic tx_done;

    logic [7:0] rx_data;
    logic rx_valid;
    logic rx_error;


    //============================================================
    // UART TX
    //============================================================

    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) tx_dut (

        .clk(clk),
        .rst(rst),

        .start(start),
        .data_in(tx_data),

        .tx(tx),
        .busy(tx_busy),
        .done(tx_done)

    );


    //============================================================
    // UART RX
    //============================================================

    uart_rx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) rx_dut (

        .clk(clk),
        .rst(rst),

        .rx(tx),

        .data_out(rx_data),
        .valid(rx_valid),
        .error(rx_error)

    );


    //============================================================
    // CLOCK
    //============================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    //============================================================
    // ASSERTION COUNTERS
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
    // TX must be HIGH while idle.
    //============================================================

    always @(posedge clk) begin

        if (!rst && !tx_busy) begin

            if (tx)
                assertion_pass(
                    "TX IDLE -> TX=1"
                );
            else
                assertion_fail(
                    "TX IDLE -> TX=1"
                );

        end

    end


    //============================================================
    // PROPERTY 2
    //
    // DONE must never remain HIGH continuously.
    //============================================================

    logic previous_done;

    always @(posedge clk) begin

        if (rst) begin

            previous_done <= 1'b0;

        end

        else begin

            if (previous_done && tx_done)
                assertion_fail(
                    "DONE must be one-cycle pulse"
                );
            else
                assertion_pass(
                    "DONE pulse behavior"
                );

            previous_done <= tx_done;

        end

    end


    //============================================================
    // PROPERTY 3
    //
    // TX DONE implies TX is no longer busy.
    //============================================================

    always @(posedge clk) begin

        if (!rst && tx_done) begin

            if (!tx_busy)
                assertion_pass(
                    "DONE -> BUSY=0"
                );
            else
                assertion_fail(
                    "DONE -> BUSY=0"
                );

        end

    end


    //============================================================
    // PROPERTY 4
    //
    // RX VALID and RX ERROR must never occur together.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (rx_valid && rx_error)

                assertion_fail(
                    "RX VALID and ERROR mutually exclusive"
                );

            else

                assertion_pass(
                    "RX VALID/ERROR mutually exclusive"
                );

        end

    end


    //============================================================
    // PROPERTY 5
    //
    // RX ERROR must not occur with a valid frame.
    //============================================================

    always @(posedge clk) begin

        if (!rst && rx_valid) begin

            if (!rx_error)
                assertion_pass(
                    "VALID -> ERROR=0"
                );
            else
                assertion_fail(
                    "VALID -> ERROR=0"
                );

        end

    end


    //============================================================
    // PROPERTY 6
    //
    // RX ERROR must be a pulse.
    //============================================================

    logic previous_error;

    always @(posedge clk) begin

        if (rst) begin

            previous_error <= 1'b0;

        end

        else begin

            if (previous_error && rx_error)

                assertion_fail(
                    "RX ERROR pulse behavior"
                );

            else

                assertion_pass(
                    "RX ERROR pulse behavior"
                );

            previous_error <= rx_error;

        end

    end


    //============================================================
    // PROPERTY 7
    //
    // TX busy must remain active during a transfer.
    //============================================================

    logic transfer_active;

    always @(posedge clk) begin

        if (rst) begin

            transfer_active <= 1'b0;

        end

        else begin

            if (start)
                transfer_active <= 1'b1;

            if (tx_done)
                transfer_active <= 1'b0;

            if (transfer_active && !tx_done) begin

                if (tx_busy)
                    assertion_pass(
                        "ACTIVE TRANSFER -> BUSY=1"
                    );
                else
                    assertion_fail(
                        "ACTIVE TRANSFER -> BUSY=1"
                    );

            end

        end

    end


    //============================================================
    // DIRECTED TEST COUNTERS
    //============================================================

    integer test_count;
    integer test_pass;
    integer test_fail;


    task automatic send_byte;

        input [7:0] data;

        begin

            @(negedge clk);

            tx_data = data;
            start   = 1'b1;

            @(negedge clk);

            start = 1'b0;

            wait (tx_done);

            @(posedge clk);

            if ((rx_valid) &&
                (rx_data === data) &&
                !rx_error) begin

                $display(
                    "PASS: TX=%02h RX=%02h EXPECTED=%02h",
                    data,
                    rx_data,
                    data
                );

                test_pass = test_pass + 1;

            end

            else begin

                $display(
                    "FAIL: TX=%02h RX=%02h EXPECTED=%02h ERROR=%b",
                    data,
                    rx_data,
                    data,
                    rx_error
                );

                test_fail = test_fail + 1;

            end

            test_count = test_count + 1;

            @(negedge clk);

        end

    endtask


    //============================================================
    // MAIN TEST
    //============================================================

    initial begin

        $dumpfile("uart_assertions.vcd");
        $dumpvars(0, uart_assertion_tb);

        assertion_checks   = 0;
        assertion_passes   = 0;
        assertion_failures = 0;

        test_count = 0;
        test_pass  = 0;
        test_fail  = 0;

        start   = 1'b0;
        tx_data = 8'h00;

        rst = 1'b1;

        repeat (3)
            @(posedge clk);

        rst = 1'b0;


        //========================================================
        // DIRECTED TESTS
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 1: DIRECTED UART ASSERTION TESTS");
        $display("==============================================");

        send_byte(8'h00);
        send_byte(8'hFF);
        send_byte(8'hA5);
        send_byte(8'h5A);
        send_byte(8'h3C);
        send_byte(8'hC3);
        send_byte(8'h55);
        send_byte(8'hAA);


        //========================================================
        // RANDOMIZED TESTS
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 2: RANDOMIZED UART ASSERTION TESTS");
        $display("==============================================");

        repeat (50) begin

            send_byte($random);

        end


        //========================================================
        // SUMMARY
        //========================================================

        $display("");
        $display("==============================================");
        $display("UART ASSERTION VERIFICATION SUMMARY");
        $display("==============================================");

        $display(
            "BYTE TESTS          = %0d",
            test_count
        );

        $display(
            "BYTE TESTS PASSED   = %0d",
            test_pass
        );

        $display(
            "BYTE TESTS FAILED   = %0d",
            test_fail
        );

        $display(
            "ASSERTION CHECKS    = %0d",
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

        if ((test_fail == 0) &&
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
            "UART ASSERTION VERIFICATION COMPLETE"
        );

        $finish;

    end

endmodule