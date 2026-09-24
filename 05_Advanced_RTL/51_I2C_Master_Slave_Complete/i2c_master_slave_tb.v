`timescale 1ns/1ps

module i2c_master_slave_tb;

    reg clk;
    reg rst;

    reg start;
    reg rw;

    reg [6:0] slave_addr;

    reg [7:0] master_tx_data;

    reg [7:0] slave_tx_data;


    wire scl;

    wire [7:0] master_rx_data;

    wire master_busy;
    wire master_done;
    wire master_ack_error;


    wire [7:0] slave_rx_data;

    wire slave_data_valid;
    wire slave_read_request;


    wire master_sda_oe;
    wire master_sda_out;

    wire slave_sda_oe;
    wire slave_sda_out;


    // =========================================================
    // OPEN-DRAIN SDA BUS
    // =========================================================

    tri1 sda_bus;

    assign sda_bus =
        (master_sda_oe || slave_sda_oe)
        ? 1'b0
        : 1'b1;


    // =========================================================
    // MASTER
    // =========================================================

    i2c_master #(
        .CLK_DIV(2)
    ) master (

        .clk(clk),
        .rst(rst),

        .start(start),
        .rw(rw),

        .slave_addr(slave_addr),
        .tx_data(master_tx_data),

        .sda_in(sda_bus),

        .scl(scl),

        .sda_out(master_sda_out),
        .sda_oe(master_sda_oe),

        .rx_data(master_rx_data),

        .busy(master_busy),
        .done(master_done),
        .ack_error(master_ack_error)

    );


    // =========================================================
    // SLAVE
    // =========================================================

    i2c_slave #(
        .SLAVE_ADDR(7'h50)
    ) slave (

        .clk(clk),
        .rst(rst),

        .scl(scl),
        .sda_in(sda_bus),

        .sda_out(slave_sda_out),
        .sda_oe(slave_sda_oe),

        .tx_data(slave_tx_data),

        .rx_data(slave_rx_data),

        .data_valid(slave_data_valid),
        .read_request(slave_read_request)

    );


    // =========================================================
    // CLOCK
    // =========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // =========================================================
    // VCD
    // =========================================================

    initial begin

        $dumpfile("i2c_master_slave.vcd");

        $dumpvars(0, i2c_master_slave_tb);

    end


    // =========================================================
    // BUS MONITOR
    // =========================================================

    always @(posedge clk) begin

        #1;

        $display(
            "TIME=%0t | SCL=%b | SDA=%b | START=%b | RW=%b | BUSY=%b | DONE=%b | ACK_ERR=%b | MASTER_RX=%h | SLAVE_RX=%h | VALID=%b | READ_REQ=%b",
            $time,
            scl,
            sda_bus,
            start,
            rw,
            master_busy,
            master_done,
            master_ack_error,
            master_rx_data,
            slave_rx_data,
            slave_data_valid,
            slave_read_request
        );

    end


    // =========================================================
    // TEST SEQUENCE
    // =========================================================

    initial begin

        // -----------------------------------------------------
        // INITIAL VALUES
        // -----------------------------------------------------

        rst = 1'b1;

        start = 1'b0;

        rw = 1'b0;

        slave_addr = 7'h50;

        master_tx_data = 8'h00;

        slave_tx_data = 8'h3C;


        #30;

        rst = 1'b0;

        #20;


        // =====================================================
        // TEST 1: MASTER -> SLAVE WRITE A5
        // =====================================================

        $display("");
        $display("==============================================");
        $display("TEST 1: MASTER -> SLAVE WRITE A5");
        $display("==============================================");


        @(negedge clk);

        slave_addr = 7'h50;

        rw = 1'b0;

        master_tx_data = 8'hA5;

        start = 1'b1;


        @(negedge clk);

        start = 1'b0;


        wait (slave_data_valid == 1'b1);

        #1;


        if (slave_rx_data == 8'hA5)

            $display(
                "PASS: SLAVE RECEIVED A5"
            );

        else

            $display(
                "FAIL: EXPECTED A5, GOT %h",
                slave_rx_data
            );


        wait (master_done == 1'b1);

        #1;


        if (!master_ack_error)

            $display(
                "PASS: WRITE ACK RECEIVED"
            );

        else

            $display(
                "FAIL: WRITE ACK ERROR"
            );


        #30;


        // =====================================================
        // TEST 2: MASTER -> SLAVE WRITE 3C
        // =====================================================

        $display("");
        $display("==============================================");
        $display("TEST 2: MASTER -> SLAVE WRITE 3C");
        $display("==============================================");


        @(negedge clk);

        slave_addr = 7'h50;

        rw = 1'b0;

        master_tx_data = 8'h3C;

        start = 1'b1;


        @(negedge clk);

        start = 1'b0;


        wait (slave_data_valid == 1'b1);

        #1;


        if (slave_rx_data == 8'h3C)

            $display(
                "PASS: SLAVE RECEIVED 3C"
            );

        else

            $display(
                "FAIL: EXPECTED 3C, GOT %h",
                slave_rx_data
            );


        wait (master_done == 1'b1);

        #1;


        if (!master_ack_error)

            $display(
                "PASS: WRITE ACK RECEIVED"
            );

        else

            $display(
                "FAIL: WRITE ACK ERROR"
            );


        #30;


        // =====================================================
        // TEST 3: SLAVE -> MASTER READ 3C
        // =====================================================

        $display("");
        $display("==============================================");
        $display("TEST 3: SLAVE -> MASTER READ 3C");
        $display("==============================================");


        @(negedge clk);

        slave_addr = 7'h50;

        rw = 1'b1;

        slave_tx_data = 8'h3C;

        start = 1'b1;


        @(negedge clk);

        start = 1'b0;


        wait (slave_read_request == 1'b1);

        $display(
            "PASS: SLAVE READ REQUEST DETECTED"
        );


        wait (master_done == 1'b1);

        #1;


        if (master_rx_data == 8'h3C)

            $display(
                "PASS: MASTER RECEIVED 3C"
            );

        else

            $display(
                "FAIL: EXPECTED MASTER RX = 3C, GOT %h",
                master_rx_data
            );


        if (!master_ack_error)

            $display(
                "PASS: READ ADDRESS ACK RECEIVED"
            );

        else

            $display(
                "FAIL: READ ADDRESS ACK ERROR"
            );


        #30;


        // =====================================================
        // TEST 4: WRONG ADDRESS -> NACK
        // =====================================================

        $display("");
        $display("==============================================");
        $display("TEST 4: WRONG ADDRESS -> NACK");
        $display("==============================================");


        @(negedge clk);

        slave_addr = 7'h51;

        rw = 1'b0;

        master_tx_data = 8'h55;

        start = 1'b1;


        @(negedge clk);

        start = 1'b0;


        wait (master_done == 1'b1);

        #1;


        if (master_ack_error)

            $display(
                "PASS: NACK DETECTED FOR WRONG ADDRESS"
            );

        else

            $display(
                "FAIL: EXPECTED NACK"
            );


        #30;


        // =====================================================
        // FINAL RESULT
        // =====================================================

        $display("");
        $display("==============================================");
        $display("I2C MASTER + SLAVE VERIFICATION COMPLETE");
        $display("==============================================");


        #20;

        $finish;

    end

endmodule