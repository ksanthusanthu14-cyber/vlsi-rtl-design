`timescale 1ns/1ps

module uart_soc_tb;

    localparam integer CLK_PER_BIT = 4;

    logic clk;
    logic rst;

    // ============================================================
    // APB SIGNALS
    // ============================================================

    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [7:0]  paddr;
    logic [31:0] pwdata;

    logic [31:0] prdata;
    logic        pready;

    // ============================================================
    // UART SIGNALS
    // ============================================================

    wire uart_tx;
    wire uart_rx;

    // UART loopback
    assign uart_rx = uart_tx;

    // ============================================================
    // COUNTERS
    // ============================================================

    integer total_checks;
    integer passed_checks;
    integer failed_checks;

    integer tx_done_checks;
    integer rx_valid_checks;
    integer data_checks;
    integer status_checks;
    integer apb_checks;

    // ============================================================
    // DUT
    // ============================================================

    uart_soc_top #(
        .CLK_PER_BIT(CLK_PER_BIT)
    ) dut (
        .clk     (clk),
        .rst     (rst),

        .psel    (psel),
        .penable (penable),
        .pwrite  (pwrite),
        .paddr   (paddr),
        .pwdata  (pwdata),

        .prdata  (prdata),
        .pready  (pready),

        .uart_tx (uart_tx),
        .uart_rx (uart_rx)
    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ============================================================
    // CHECK VALUE
    // ============================================================

    task automatic check_value;

        input [31:0] actual;
        input [31:0] expected;
        input [255:0] message;

        begin

            total_checks = total_checks + 1;

            if (actual === expected) begin

                passed_checks = passed_checks + 1;

                $display(
                    "PASS: %s | Actual = %h | Expected = %h",
                    message,
                    actual,
                    expected
                );

            end
            else begin

                failed_checks = failed_checks + 1;

                $display(
                    "FAIL: %s | Actual = %h | Expected = %h",
                    message,
                    actual,
                    expected
                );

            end

        end

    endtask


    // ============================================================
    // APB WRITE
    // ============================================================

    task automatic apb_write;

        input [7:0] address;
        input [31:0] data;

        begin

            // APB SETUP phase
            @(posedge clk);

            psel    <= 1'b1;
            penable <= 1'b0;
            pwrite  <= 1'b1;
            paddr   <= address;
            pwdata  <= data;

            // APB ACCESS phase
            @(posedge clk);

            penable <= 1'b1;

            // Wait for PREADY
            while (!pready)
                @(posedge clk);

            // Complete transaction
            @(posedge clk);

            psel    <= 1'b0;
            penable <= 1'b0;
            pwrite  <= 1'b0;
            paddr   <= 8'h00;
            pwdata  <= 32'h00000000;

            apb_checks = apb_checks + 1;

        end

    endtask


    // ============================================================
    // APB READ
    // ============================================================

    task automatic apb_read;

        input  [7:0]  address;
        output [31:0] data;

        begin

            // APB SETUP
            @(posedge clk);

            psel    <= 1'b1;
            penable <= 1'b0;
            pwrite  <= 1'b0;
            paddr   <= address;
            pwdata  <= 32'h00000000;

            // APB ACCESS
            @(posedge clk);

            penable <= 1'b1;

            while (!pready)
                @(posedge clk);

            #1;

            data = prdata;

            // Complete transaction
            @(posedge clk);

            psel    <= 1'b0;
            penable <= 1'b0;
            paddr   <= 8'h00;

            apb_checks = apb_checks + 1;

        end

    endtask


    // ============================================================
    // UART TRANSACTION MONITOR
    //
    // IMPORTANT:
    // TX DONE and RX VALID are monitored simultaneously.
    // This prevents the testbench from missing the one-cycle
    // RX VALID pulse.
    // ============================================================

    task automatic monitor_uart_transaction;

        input [7:0] expected_data;

        integer local_timeout;
        integer found_tx_done;
        integer found_rx_valid;

        begin

            local_timeout = 0;
            found_tx_done = 0;
            found_rx_valid = 0;

            while (
                (local_timeout < 1000) &&
                ((found_tx_done == 0) || (found_rx_valid == 0))
            ) begin

                @(posedge clk);

                // Allow DUT nonblocking assignments to update
                #1;

                // Monitor TX DONE
                if (dut.u_apb_uart.tx_done) begin
                    found_tx_done = 1;
                end

                // Monitor RX VALID
                if (dut.u_apb_uart.rx_valid) begin
                    found_rx_valid = 1;
                end

                local_timeout = local_timeout + 1;

            end


            // ====================================================
            // TX DONE CHECK
            // ====================================================

            total_checks = total_checks + 1;

            if (found_tx_done) begin

                passed_checks = passed_checks + 1;
                tx_done_checks = tx_done_checks + 1;

                $display(
                    "PASS: UART TX DONE detected"
                );

            end
            else begin

                failed_checks = failed_checks + 1;

                $display(
                    "FAIL: UART TX DONE timeout"
                );

            end


            // ====================================================
            // RX VALID CHECK
            // ====================================================

            total_checks = total_checks + 1;

            if (found_rx_valid) begin

                passed_checks = passed_checks + 1;
                rx_valid_checks = rx_valid_checks + 1;

                $display(
                    "PASS: UART RX VALID detected"
                );

            end
            else begin

                failed_checks = failed_checks + 1;

                $display(
                    "FAIL: UART RX VALID timeout"
                );

            end


            // ====================================================
            // RX DATA CHECK
            // ====================================================

            total_checks = total_checks + 1;

            if (dut.u_apb_uart.rx_data === expected_data) begin

                passed_checks = passed_checks + 1;
                data_checks = data_checks + 1;

                $display(
                    "PASS: RX DATA | Received = %h | Expected = %h",
                    dut.u_apb_uart.rx_data,
                    expected_data
                );

            end
            else begin

                failed_checks = failed_checks + 1;

                $display(
                    "FAIL: RX DATA | Received = %h | Expected = %h",
                    dut.u_apb_uart.rx_data,
                    expected_data
                );

            end

        end

    endtask


    // ============================================================
    // STATUS REGISTER CHECK
    // ============================================================

    task automatic check_status;

        input [31:0] expected_status;

        reg [31:0] status_value;

        begin

            apb_read(
                8'h04,
                status_value
            );

            total_checks = total_checks + 1;

            if (status_value === expected_status) begin

                passed_checks = passed_checks + 1;
                status_checks = status_checks + 1;

                $display(
                    "PASS: STATUS REGISTER | Value = %h",
                    status_value
                );

            end
            else begin

                failed_checks = failed_checks + 1;

                $display(
                    "FAIL: STATUS REGISTER | Value = %h | Expected = %h",
                    status_value,
                    expected_status
                );

            end

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // Initial APB values
        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 8'h00;
        pwdata  = 32'h00000000;

        // Counters
        total_checks    = 0;
        passed_checks   = 0;
        failed_checks   = 0;

        tx_done_checks  = 0;
        rx_valid_checks = 0;
        data_checks     = 0;
        status_checks   = 0;
        apb_checks      = 0;


        // ========================================================
        // RESET
        // ========================================================

        $display("");
        $display("================================================");
        $display("          UART SoC PERIPHERAL TEST");
        $display("================================================");

        $display("");
        $display("Applying reset...");

        rst = 1'b1;

        repeat (3)
            @(posedge clk);

        rst = 1'b0;

        repeat (2)
            @(posedge clk);

        $display("Reset released.");
        $display("");


        // ========================================================
        // APB CONTROL REGISTER TEST
        // ========================================================

        $display("-----------------------------------------------");
        $display("APB CONTROL REGISTER TEST");
        $display("-----------------------------------------------");

        apb_write(
            8'h08,
            32'h00000001
        );

        begin : control_read_block

            reg [31:0] control_value;

            apb_read(
                8'h08,
                control_value
            );

            check_value(
                control_value,
                32'h00000001,
                "CONTROL REGISTER"
            );

        end


        // ========================================================
        // UART LOOPBACK TEST 1
        // ========================================================

        $display("");
        $display("-----------------------------------------------");
        $display("UART LOOPBACK TEST 1");
        $display("-----------------------------------------------");

        apb_write(
            8'h00,
            32'h00000055
        );

        monitor_uart_transaction(
            8'h55
        );


        // ========================================================
        // UART LOOPBACK TEST 2
        // ========================================================

        $display("");
        $display("-----------------------------------------------");
        $display("UART LOOPBACK TEST 2");
        $display("-----------------------------------------------");

        apb_write(
            8'h00,
            32'h000000A5
        );

        monitor_uart_transaction(
            8'hA5
        );


        // ========================================================
        // UART LOOPBACK TEST 3
        // ========================================================

        $display("");
        $display("-----------------------------------------------");
        $display("UART LOOPBACK TEST 3");
        $display("-----------------------------------------------");

        apb_write(
            8'h00,
            32'h0000003C
        );

        monitor_uart_transaction(
            8'h3C
        );


        // ========================================================
        // STATUS REGISTER TEST
        // ========================================================

        $display("");
        $display("-----------------------------------------------");
        $display("STATUS REGISTER TEST");
        $display("-----------------------------------------------");

        /*
         * STATUS REGISTER
         *
         * bit 0 = TX_BUSY
         * bit 1 = TX_DONE
         * bit 2 = RX_VALID
         * bit 3 = RX_ERROR
         */

        check_status(
            32'h00000000
        );


        // ========================================================
        // FINAL SUMMARY
        // ========================================================

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display("");
        $display("APB TRANSACTIONS      = %0d", apb_checks);
        $display("TX DONE CHECKS        = %0d", tx_done_checks);
        $display("RX VALID CHECKS       = %0d", rx_valid_checks);
        $display("DATA CHECKS           = %0d", data_checks);
        $display("STATUS CHECKS         = %0d", status_checks);

        $display("");
        $display("TOTAL CHECKS          = %0d", total_checks);
        $display("PASSED CHECKS         = %0d", passed_checks);
        $display("FAILED CHECKS         = %0d", failed_checks);

        $display("");

        if (failed_checks == 0)
            $display("OVERALL RESULT = PASS");
        else
            $display("OVERALL RESULT = FAIL");

        $display("================================================");

        $finish;

    end

endmodule