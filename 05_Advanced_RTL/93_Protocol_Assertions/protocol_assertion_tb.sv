`timescale 1ns/1ps

module protocol_assertion_tb;

    localparam int TIMEOUT = 8;


    //============================================================
    // CLOCK / RESET
    //============================================================

    logic clk;
    logic rst;


    //============================================================
    // MASTER SIGNALS
    //============================================================

    logic       start;
    logic [7:0] tx_data;

    logic       req;
    logic [7:0] master_data;

    logic       busy;
    logic       done;
    logic       timeout;


    //============================================================
    // SLAVE SIGNALS
    //============================================================

    logic       ack;
    logic [7:0] slave_data;

    logic [7:0] response_data;
    logic       data_valid;


    //============================================================
    // MASTER
    //============================================================

    protocol_master #(
        .TIMEOUT(TIMEOUT)
    ) master (

        .clk(clk),
        .rst(rst),

        .start(start),
        .tx_data(tx_data),

        .ack(ack),
        .rx_data(response_data),

        .req(req),
        .data_out(master_data),

        .busy(busy),
        .done(done),
        .timeout(timeout)

    );


    //============================================================
    // SLAVE
    //============================================================

    protocol_slave slave (

        .clk(clk),
        .rst(rst),

        .req(req),
        .data_in(master_data),

        .ack(ack),
        .data_out(slave_data),
        .data_valid(data_valid)

    );


    //============================================================
    // CLOCK
    //============================================================

    initial begin

        clk = 0;

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

            assertion_checks = assertion_checks + 1;
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
    // ACK requires REQ.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (ack && !req)

                assertion_fail(
                    "ACK requires REQ"
                );

            else

                assertion_pass(
                    "ACK requires REQ"
                );

        end

    end


    //============================================================
    // PROPERTY 2
    //
    // DATA_VALID requires ACK.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (data_valid && !ack)

                assertion_fail(
                    "DATA_VALID requires ACK"
                );

            else

                assertion_pass(
                    "DATA_VALID requires ACK"
                );

        end

    end


    //============================================================
    // PROPERTY 3
    //
    // BUSY must be active while REQ is active.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (req && !busy)

                assertion_fail(
                    "REQ requires BUSY"
                );

            else

                assertion_pass(
                    "REQ requires BUSY"
                );

        end

    end


    //============================================================
    // PROPERTY 4
    //
    // DONE must not occur while BUSY.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (done && busy)

                assertion_fail(
                    "DONE requires BUSY=0"
                );

            else

                assertion_pass(
                    "DONE requires BUSY=0"
                );

        end

    end


    //============================================================
    // PROPERTY 5
    //
    // TIMEOUT and DONE cannot occur together.
    //============================================================

    always @(posedge clk) begin

        if (!rst) begin

            if (timeout && done)

                assertion_fail(
                    "TIMEOUT and DONE mutually exclusive"
                );

            else

                assertion_pass(
                    "TIMEOUT/DONE mutually exclusive"
                );

        end

    end


    //============================================================
    // PROPERTY 6
    //
    // TIMEOUT must clear BUSY.
    //============================================================

    always @(posedge clk) begin

        if (!rst && timeout) begin

            if (!busy)

                assertion_pass(
                    "TIMEOUT -> BUSY=0"
                );

            else

                assertion_fail(
                    "TIMEOUT -> BUSY=0"
                );

        end

    end


    //============================================================
    // PROPERTY 7
    //
    // REQ must remain stable during BUSY.
    //============================================================

    logic previous_req;

    always @(posedge clk) begin

        if (rst) begin

            previous_req <= 0;

        end

        else begin

            if (busy && previous_req && !req)

                assertion_fail(
                    "REQ stable during transaction"
                );

            else

                assertion_pass(
                    "REQ stable during transaction"
                );

            previous_req <= req;

        end

    end


    //============================================================
    // PROPERTY 8
    //
    // No DATA_VALID without a transaction.
    //============================================================

    logic transaction_active;

    always @(posedge clk) begin

        if (rst) begin

            transaction_active <= 0;

        end

        else begin

            if (start)
                transaction_active <= 1;

            if (done || timeout)
                transaction_active <= 0;

            if (data_valid && !transaction_active)

                assertion_fail(
                    "DATA_VALID requires transaction"
                );

            else

                assertion_pass(
                    "DATA_VALID requires transaction"
                );

        end

    end


    //============================================================
    // DIRECTED TEST COUNTERS
    //============================================================

    integer test_count;
    integer test_pass;
    integer test_fail;


    //============================================================
    // NORMAL TRANSACTION TASK
    //============================================================

    task automatic normal_transaction;

        input [7:0] data;

        begin

            @(negedge clk);

            tx_data = data;
            start   = 1;

            @(negedge clk);

            start = 0;

            wait(done);

            @(posedge clk);

            if (slave_data === data) begin

                $display(
                    "PASS: TX=%02h RX=%02h",
                    data,
                    slave_data
                );

                test_pass = test_pass + 1;

            end

            else begin

                $display(
                    "FAIL: TX=%02h RX=%02h",
                    data,
                    slave_data
                );

                test_fail = test_fail + 1;

            end

            test_count = test_count + 1;

        end

    endtask


    //============================================================
    // MAIN TEST
    //============================================================

    initial begin

        $dumpfile("protocol_assertions.vcd");
        $dumpvars(0, protocol_assertion_tb);


        assertion_checks   = 0;
        assertion_passes   = 0;
        assertion_failures = 0;

        test_count = 0;
        test_pass  = 0;
        test_fail  = 0;


        start   = 0;
        tx_data = 0;


        //========================================================
        // RESET
        //========================================================

        rst = 1;

        repeat(3)
            @(posedge clk);

        rst = 0;


        //========================================================
        // TEST 1 — NORMAL TRANSACTIONS
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 1: NORMAL PROTOCOL TRANSACTIONS");
        $display("==============================================");

        normal_transaction(8'hA5);
        normal_transaction(8'h3C);
        normal_transaction(8'h55);
        normal_transaction(8'hAA);


        //========================================================
        // TEST 2 — RANDOMIZED TRANSACTIONS
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 2: RANDOMIZED PROTOCOL TRANSACTIONS");
        $display("==============================================");

        repeat(20) begin

            normal_transaction($random);

        end


        //========================================================
        // SUMMARY
        //========================================================

        $display("");
        $display("==============================================");
        $display("PROTOCOL ASSERTION VERIFICATION SUMMARY");
        $display("==============================================");

        $display(
            "TRANSACTION TESTS   = %0d",
            test_count
        );

        $display(
            "TRANSACTIONS PASSED = %0d",
            test_pass
        );

        $display(
            "TRANSACTIONS FAILED = %0d",
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
            "PROTOCOL ASSERTION VERIFICATION COMPLETE"
        );

        $finish;

    end

endmodule