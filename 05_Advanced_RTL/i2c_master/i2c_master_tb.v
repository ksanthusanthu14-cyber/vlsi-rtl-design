`timescale 1ns/1ps

module i2c_master_tb;

    reg clk;
    reg rst;

    reg start;

    reg [6:0] slave_addr;
    reg [7:0] tx_data;

    wire scl;

    wire sda_out;
    wire sda_oe;

    wire busy;
    wire done;
    wire ack_error;

    reg slave_drive_low;

    wire sda_bus;


    // =========================================================
    // I2C OPEN-DRAIN BUS
    // =========================================================

    assign sda_bus =
        (sda_oe || slave_drive_low) ? 1'b0 : 1'b1;


    // =========================================================
    // DUT
    // =========================================================

    i2c_master #(
        .CLK_DIV(4)
    ) dut (

        .clk(clk),
        .rst(rst),

        .start(start),

        .slave_addr(slave_addr),
        .tx_data(tx_data),

        .sda_in(sda_bus),

        .scl(scl),
        .sda_out(sda_out),
        .sda_oe(sda_oe),

        .busy(busy),
        .done(done),
        .ack_error(ack_error)

    );


    // =========================================================
    // SYSTEM CLOCK
    // =========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // =========================================================
    // VCD
    // =========================================================

    initial begin

        $dumpfile("i2c_master_tb.vcd");

        $dumpvars(0, i2c_master_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | START=%b | BUSY=%b | DONE=%b | SCL=%b | SDA=%b | SDA_OE=%b | ADDR=%h | TX=%h | ACK_ERR=%b",
            $time,
            start,
            busy,
            done,
            scl,
            sda_bus,
            sda_oe,
            slave_addr,
            tx_data,
            ack_error
        );

    end


    // =========================================================
    // SIMPLE SLAVE ACK MODEL
    //
    // ACK is generated when the master releases SDA.
    // The transaction has two ACK phases:
    //
    // 1. Address ACK
    // 2. Data ACK
    //
    // We detect them from the DUT state.
    // =========================================================

    always @(*) begin

        slave_drive_low = 1'b0;

        if (dut.state == 4'd3)
            slave_drive_low = 1'b1;

        else if (dut.state == 4'd6)
            slave_drive_low = 1'b0;

        // DATA_ACK is state 5.
        // Keep SDA LOW for data ACK.
        if (dut.state == 4'd5)
            slave_drive_low = 1'b1;

    end


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        rst        = 1'b1;
        start      = 1'b0;

        slave_addr = 7'h50;
        tx_data    = 8'hA5;


        // Reset
        #30;

        rst = 1'b0;


        // =====================================================
        // TEST 1
        // Address 50
        // Data A5
        // =====================================================

        #20;

        start = 1'b1;

        // Keep START HIGH until master accepts it
        wait (busy == 1'b1);

        start = 1'b0;

        wait (done == 1'b1);

        #20;


        // =====================================================
        // TEST 2
        // Address 50
        // Data 3C
        // =====================================================

        tx_data = 8'h3C;

        start = 1'b1;

        wait (busy == 1'b1);

        start = 1'b0;

        wait (done == 1'b1);

        #20;


        // =====================================================
        // FINISH
        // =====================================================

        $display("");
        $display("==============================================");
        $display("I2C MASTER TEST COMPLETED");
        $display("==============================================");
        $display("");

        $finish;

    end


    // =========================================================
    // RESULT CHECK
    // =========================================================

    always @(posedge done) begin

        if (ack_error == 1'b0) begin

            $display(
                "PASS: I2C WRITE | ADDRESS=%h | DATA=%h | ACK=OK",
                slave_addr,
                tx_data
            );

        end

        else begin

            $display(
                "FAIL: I2C WRITE | ADDRESS=%h | DATA=%h | ACK ERROR",
                slave_addr,
                tx_data
            );

        end

    end

endmodule