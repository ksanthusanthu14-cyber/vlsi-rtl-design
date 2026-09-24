`timescale 1ns/1ps

module spi_slave_tb;

    reg rst;
    reg sclk;
    reg cs_n;
    reg mosi;

    wire miso;

    reg  [7:0] tx_data;
    wire [7:0] rx_data;

    wire done;

    reg [7:0] master_tx;
    reg [7:0] master_rx;

    integer i;


    // =========================================================
    // DUT
    // =========================================================

    spi_slave #(
        .DATA_WIDTH(8)
    ) dut (
        .rst(rst),

        .sclk(sclk),
        .cs_n(cs_n),
        .mosi(mosi),
        .miso(miso),

        .tx_data(tx_data),
        .rx_data(rx_data),

        .done(done)
    );


    // =========================================================
    // VCD
    // =========================================================

    initial begin

        $dumpfile("spi_slave_tb.vcd");
        $dumpvars(0, spi_slave_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | CS=%b | SCLK=%b | MOSI=%b | MISO=%b | TX=%h | RX=%h | DONE=%b",
            $time,
            cs_n,
            sclk,
            mosi,
            miso,
            tx_data,
            rx_data,
            done
        );

    end


    // =========================================================
    // SPI TRANSFER TASK
    //
    // SPI Mode 0
    //
    // Data must be stable before rising edge.
    // Slave samples MOSI on rising edge.
    // Slave changes MISO on falling edge.
    // =========================================================

    task spi_transfer;

        input [7:0] tx_byte;
        begin

            master_tx = tx_byte;
            master_rx = 8'h00;

            // -------------------------------------------------
            // Activate slave
            // -------------------------------------------------

            cs_n = 1'b0;

            #2;


            // -------------------------------------------------
            // Transfer 8 bits, MSB first
            // -------------------------------------------------

            for (i = 7; i >= 0; i = i - 1) begin

                // Put next MOSI bit on bus
                mosi = master_tx[i];

                // Allow data setup time
                #8;

                // ---------------------------------------------
                // Rising edge
                // Slave samples MOSI
                // Master samples MISO
                // ---------------------------------------------

                sclk = 1'b1;

                #1;

                master_rx[i] = miso;

                #1;


                // ---------------------------------------------
                // Falling edge
                // Slave changes MISO
                // ---------------------------------------------

                sclk = 1'b0;

                #8;

            end


            // -------------------------------------------------
            // Deactivate slave
            // -------------------------------------------------

            cs_n = 1'b1;

            mosi = 1'b0;

            #5;


            $display(
                "SPI TRANSFER COMPLETE | MASTER TX=%h | MASTER RX=%h | SLAVE TX=%h | SLAVE RX=%h",
                master_tx,
                master_rx,
                tx_data,
                rx_data
            );


            // -------------------------------------------------
            // Verification
            // -------------------------------------------------

            if (master_rx == tx_data && rx_data == master_tx) begin

                $display(
                    "PASS: MASTER TX=%h -> SLAVE RX=%h | SLAVE TX=%h -> MASTER RX=%h",
                    master_tx,
                    rx_data,
                    tx_data,
                    master_rx
                );

            end

            else begin

                $display(
                    "FAIL: MASTER TX=%h | MASTER RX=%h | SLAVE TX=%h | SLAVE RX=%h",
                    master_tx,
                    master_rx,
                    tx_data,
                    rx_data
                );

            end

        end

    endtask


    // =========================================================
    // TEST SEQUENCE
    // =========================================================

    initial begin

        // Initial state
        rst     = 1'b1;
        sclk    = 1'b0;
        cs_n    = 1'b1;
        mosi    = 1'b0;

        tx_data = 8'h00;

        master_tx = 8'h00;
        master_rx = 8'h00;


        // -----------------------------------------------------
        // Reset
        // -----------------------------------------------------

        #20;

        rst = 1'b0;


        // =====================================================
        // TEST 1
        //
        // Master -> A5
        // Slave  -> 3C
        // =====================================================

        #20;

        tx_data = 8'h3C;

        spi_transfer(8'hA5);


        // =====================================================
        // TEST 2
        //
        // Master -> 55
        // Slave  -> F0
        // =====================================================

        #20;

        tx_data = 8'hF0;

        spi_transfer(8'h55);


        // =====================================================
        // TEST 3
        //
        // Master -> 00
        // Slave  -> FF
        // =====================================================

        #20;

        tx_data = 8'hFF;

        spi_transfer(8'h00);


        // =====================================================
        // Finish
        // =====================================================

        #20;

        $finish;

    end


    // =========================================================
    // DONE MONITOR
    // =========================================================

    always @(posedge done) begin

        $display(
            "SLAVE DONE | RX_DATA=%h",
            rx_data
        );

    end

endmodule