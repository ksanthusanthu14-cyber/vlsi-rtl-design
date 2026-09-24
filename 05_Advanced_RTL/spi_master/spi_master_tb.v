`timescale 1ns/1ps

module spi_master_tb;

    // =========================================================
    // Signals
    // =========================================================

    reg clk;
    reg rst;
    reg start;

    reg [7:0] tx_data;
    reg miso;

    wire mosi;
    wire sclk;
    wire cs_n;

    wire [7:0] rx_data;

    wire busy;
    wire done;


    // =========================================================
    // SPI Slave Model
    // =========================================================

    reg [7:0] slave_data;
    reg [3:0] slave_bit_count;


    // =========================================================
    // DUT
    // =========================================================

    spi_master #(
        .DATA_WIDTH(8),
        .CLK_DIV(2)
    ) dut (

        .clk(clk),
        .rst(rst),
        .start(start),

        .tx_data(tx_data),
        .miso(miso),

        .mosi(mosi),
        .sclk(sclk),
        .cs_n(cs_n),

        .rx_data(rx_data),

        .busy(busy),
        .done(done)

    );


    // =========================================================
    // Clock Generation
    // 10 ns clock period
    // =========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // =========================================================
    // SPI SLAVE
    //
    // SPI Mode 0:
    //
    // CPOL = 0
    // CPHA = 0
    //
    // Data changes on falling edge.
    // Master samples on rising edge.
    // =========================================================


    // CS becomes active
    // Immediately place first MSB on MISO.

    always @(negedge cs_n) begin

        slave_bit_count <= 4'd0;

        miso <= slave_data[7];

    end


    // CS becomes inactive

    always @(posedge cs_n) begin

        slave_bit_count <= 4'd0;

        miso <= 1'b0;

    end


    // Change MISO on falling edge

    always @(negedge sclk) begin

        if (!cs_n) begin

            if (slave_bit_count < 4'd7) begin

                slave_bit_count <= slave_bit_count + 1'b1;

                miso <= slave_data[
                    7 - (slave_bit_count + 1'b1)
                ];

            end

        end

    end


    // =========================================================
    // Waveform
    // =========================================================

    initial begin

        $dumpfile("spi_master_tb.vcd");

        $dumpvars(0, spi_master_tb);

    end


    // =========================================================
    // Monitor
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | START=%b | TX=%h | RX=%h | CS=%b | SCLK=%b | MOSI=%b | MISO=%b | BUSY=%b | DONE=%b",
            $time,
            start,
            tx_data,
            rx_data,
            cs_n,
            sclk,
            mosi,
            miso,
            busy,
            done
        );

    end


    // =========================================================
    // TEST SEQUENCE
    // =========================================================

    initial begin

        // -----------------------------------------------------
        // Initial values
        // -----------------------------------------------------

        rst             = 1'b1;
        start           = 1'b0;

        tx_data         = 8'h00;

        slave_data      = 8'h00;

        miso            = 1'b0;

        slave_bit_count = 4'd0;


        // -----------------------------------------------------
        // Reset
        // -----------------------------------------------------

        #20;

        rst = 1'b0;


        // =====================================================
        // TEST 1
        //
        // Master sends A5
        // Slave sends 3C
        // =====================================================

        #20;

        tx_data    = 8'hA5;

        slave_data = 8'h3C;

        start      = 1'b1;

        #10;

        start      = 1'b0;


        // Wait for transfer

        #400;


        // =====================================================
        // TEST 2
        //
        // Master sends 55
        // Slave sends F0
        // =====================================================

        tx_data    = 8'h55;

        slave_data = 8'hF0;

        start      = 1'b1;

        #10;

        start      = 1'b0;


        // Wait for transfer

        #400;


        // =====================================================
        // END
        // =====================================================

        $finish;

    end


    // =========================================================
    // AUTOMATIC CHECKS
    // =========================================================

    always @(posedge done) begin

        #1;

        if (tx_data == 8'hA5 && rx_data == 8'h3C) begin

            $display(
                "PASS: SPI TEST 1 | TX=A5 | RX=3C"
            );

        end

        else if (tx_data == 8'h55 && rx_data == 8'hF0) begin

            $display(
                "PASS: SPI TEST 2 | TX=55 | RX=F0"
            );

        end

        else begin

            $display(
                "CHECK: TX=%h | RX=%h",
                tx_data,
                rx_data
            );

        end

    end

endmodule