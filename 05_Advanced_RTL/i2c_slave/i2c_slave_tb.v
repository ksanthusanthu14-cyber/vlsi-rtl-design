`timescale 1ns/1ps

module i2c_slave_tb;

    reg rst;

    reg scl;

    reg master_sda_oe;

    wire slave_sda_oe;

    wire sda;

    reg [7:0] slave_tx_data;

    wire [7:0] rx_data;

    wire data_valid;

    wire read_request;


    // =========================================================
    // OPEN-DRAIN SDA
    // =========================================================

    assign sda =
        (master_sda_oe || slave_sda_oe) ? 1'b0 : 1'b1;


    // =========================================================
    // DUT
    // =========================================================

    i2c_slave #(
        .SLAVE_ADDR(7'h50)
    ) dut (

        .rst(rst),

        .scl(scl),

        .sda_in(sda),

        .sda_out(),

        .sda_oe(slave_sda_oe),

        .tx_data(slave_tx_data),

        .rx_data(rx_data),

        .data_valid(data_valid),

        .read_request(read_request)

    );


    // =========================================================
    // VCD
    // =========================================================

    initial begin

        $dumpfile("i2c_slave_tb.vcd");

        $dumpvars(0, i2c_slave_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | SCL=%b | SDA=%b | MASTER_OE=%b | SLAVE_OE=%b | STATE=%d | RX=%h | VALID=%b | READ_REQ=%b",
            $time,
            scl,
            sda,
            master_sda_oe,
            slave_sda_oe,
            dut.state,
            rx_data,
            data_valid,
            read_request
        );

    end


    // =========================================================
    // START
    // =========================================================

    task i2c_start;

        begin

            // Bus idle

            master_sda_oe = 1'b0;

            scl = 1'b1;

            #20;

            // START:
            // SDA HIGH -> LOW while SCL HIGH

            master_sda_oe = 1'b1;

            #20;

            scl = 1'b0;

            #20;

        end

    endtask


    // =========================================================
    // STOP
    // =========================================================

    task i2c_stop;

        begin

            // SDA LOW

            master_sda_oe = 1'b1;

            scl = 1'b0;

            #20;

            // SCL HIGH

            scl = 1'b1;

            #20;

            // STOP:
            // SDA LOW -> HIGH while SCL HIGH

            master_sda_oe = 1'b0;

            #20;

        end

    endtask


    // =========================================================
    // WRITE BYTE
    // =========================================================

    task i2c_write_byte;

        input [7:0] data;

        integer i;

        begin

            for (i = 7; i >= 0; i = i - 1) begin

                // SCL LOW

                scl = 1'b0;

                // Open drain:
                // 0 -> pull LOW
                // 1 -> release HIGH

                if (data[i] == 1'b0)
                    master_sda_oe = 1'b1;
                else
                    master_sda_oe = 1'b0;

                #20;


                // SCL HIGH

                scl = 1'b1;

                #20;

            end


            // =================================================
            // ACK CLOCK
            // =================================================

            scl = 1'b0;

            master_sda_oe = 1'b0;

            #20;

            scl = 1'b1;

            #20;

            scl = 1'b0;

            #20;

        end

    endtask


    // =========================================================
    // READ BYTE
    // =========================================================

    task i2c_read_byte;

        integer i;

        reg [7:0] received;

        begin

            received = 8'h00;

            // Master releases SDA

            master_sda_oe = 1'b0;


            for (i = 7; i >= 0; i = i - 1) begin

                // SCL LOW

                scl = 1'b0;

                #20;


                // Slave should have placed bit on SDA

                scl = 1'b1;

                #10;

                received[i] = sda;

                #10;

            end


            // =================================================
            // Master NACK
            // =================================================

            scl = 1'b0;

            master_sda_oe = 1'b0;

            #20;

            scl = 1'b1;

            #20;

            scl = 1'b0;

            #20;


            $display(
                "MASTER RECEIVED DATA = %h",
                received
            );


            if (received == slave_tx_data) begin

                $display(
                    "PASS: MASTER RECEIVED %h FROM SLAVE",
                    received
                );

            end

            else begin

                $display(
                    "FAIL: MASTER RECEIVED %h, EXPECTED %h",
                    received,
                    slave_tx_data
                );

            end

        end

    endtask


    // =========================================================
    // DATA VALID
    // =========================================================

    always @(posedge data_valid) begin

        $display(
            "SLAVE DATA VALID: RX_DATA=%h",
            rx_data
        );

    end


    // =========================================================
    // READ REQUEST
    // =========================================================

    always @(posedge read_request) begin

        $display(
            "SLAVE READ REQUEST: TX_DATA=%h",
            slave_tx_data
        );

    end


    // =========================================================
    // MAIN TEST
    // =========================================================

    initial begin

        rst = 1'b1;

        scl = 1'b1;

        master_sda_oe = 1'b0;

        slave_tx_data = 8'h3C;


        #50;

        rst = 1'b0;

        #50;


        // =====================================================
        // TEST 1
        // WRITE A5
        // =====================================================

        $display("");
        $display("==============================================");
        $display("TEST 1: MASTER -> SLAVE WRITE");
        $display("==============================================");


        i2c_start;


        // 0x50 + WRITE = A0

        i2c_write_byte(8'hA0);


        // Data = A5

        i2c_write_byte(8'hA5);


        i2c_stop;


        #50;


        if (rx_data == 8'hA5) begin

            $display(
                "PASS: SLAVE RECEIVED DATA = %h",
                rx_data
            );

        end

        else begin

            $display(
                "FAIL: SLAVE RECEIVED DATA = %h",
                rx_data
            );

        end


        // =====================================================
        // TEST 2
        // READ 3C
        // =====================================================

        $display("");
        $display("==============================================");
        $display("TEST 2: SLAVE -> MASTER READ");
        $display("==============================================");


        slave_tx_data = 8'h3C;


        i2c_start;


        // 0x50 + READ = A1

        i2c_write_byte(8'hA1);


        // Read byte

        i2c_read_byte;


        i2c_stop;


        #50;


        $display("");
        $display("==============================================");
        $display("I2C SLAVE TEST COMPLETED");
        $display("==============================================");


        $finish;

    end

endmodule