`timescale 1ns/1ps

module uart_tb;

    localparam int DATA_WIDTH   = 8;
    localparam int CLKS_PER_BIT = 4;

    logic clk;
    logic rst;

    logic                  tx_start;
    logic [DATA_WIDTH-1:0] tx_data;

    logic tx;
    logic tx_busy;
    logic tx_done;

    logic [DATA_WIDTH-1:0] rx_data;
    logic rx_valid;
    logic rx_busy;
    logic rx_error;


    //==================================================
    // UART TX
    //==================================================

    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) transmitter (

        .clk(clk),
        .rst(rst),

        .tx_start(tx_start),
        .tx_data(tx_data),

        .tx(tx),
        .tx_busy(tx_busy),
        .tx_done(tx_done)

    );


    //==================================================
    // UART RX
    //==================================================

    uart_rx #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) receiver (

        .clk(clk),
        .rst(rst),

        .rx(tx),

        .rx_data(rx_data),
        .rx_valid(rx_valid),
        .rx_busy(rx_busy),
        .rx_error(rx_error)

    );


    //==================================================
    // CLOCK
    //==================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    //==================================================
    // UART TRANSMISSION TASK
    //==================================================

    task automatic send_byte(
        input logic [DATA_WIDTH-1:0] value,
        input logic [DATA_WIDTH-1:0] expected
    );

        begin

            // Wait until transmitter is idle
            wait(tx_busy == 1'b0);

            @(negedge clk);

            tx_data  = value;
            tx_start = 1'b1;

            @(posedge clk);

            #1;

            tx_start = 1'b0;


            // Wait for receiver
            wait(rx_valid == 1'b1);

            #1;

            if (rx_data === expected) begin

                $display(
                    "PASS: TX=%h | RX=%h | EXPECTED=%h | RX_ERROR=%b",
                    value,
                    rx_data,
                    expected,
                    rx_error
                );

            end

            else begin

                $display(
                    "FAIL: TX=%h | RX=%h | EXPECTED=%h | RX_ERROR=%b",
                    value,
                    rx_data,
                    expected,
                    rx_error
                );

            end

            if (rx_error == 1'b0)
                $display("PASS: UART FRAME VALID");
            else
                $display("FAIL: UART FRAME ERROR");

        end

    endtask


    //==================================================
    // TEST
    //==================================================

    initial begin

        $dumpfile("uart.vcd");
        $dumpvars(0, uart_tb);


        // Initial state
        rst      = 1'b1;
        tx_start = 1'b0;
        tx_data  = '0;


        // Reset
        #12;

        rst = 1'b0;


        $display("");
        $display("==============================================");
        $display("SYSTEMVERILOG UART VERIFICATION");
        $display("==============================================");


        //================================================
        // TEST 1
        //================================================

        $display("");
        $display("TEST 1: 0xA5");

        send_byte(
            8'hA5,
            8'hA5
        );


        //================================================
        // TEST 2
        //================================================

        $display("");
        $display("TEST 2: 0x3C");

        send_byte(
            8'h3C,
            8'h3C
        );


        //================================================
        // TEST 3
        //================================================

        $display("");
        $display("TEST 3: 0x00");

        send_byte(
            8'h00,
            8'h00
        );


        //================================================
        // TEST 4
        //================================================

        $display("");
        $display("TEST 4: 0xFF");

        send_byte(
            8'hFF,
            8'hFF
        );


        //================================================
        // TEST 5
        //================================================

        $display("");
        $display("TEST 5: 0x55");

        send_byte(
            8'h55,
            8'h55
        );


        //================================================
        // TEST 6
        //================================================

        $display("");
        $display("TEST 6: 0xAA");

        send_byte(
            8'hAA,
            8'hAA
        );


        //================================================
        // COMPLETE
        //================================================

        $display("");
        $display("==============================================");
        $display("SYSTEMVERILOG UART VERIFICATION COMPLETE");
        $display("==============================================");

        $finish;

    end

endmodule