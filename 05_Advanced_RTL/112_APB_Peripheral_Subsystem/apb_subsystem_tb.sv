`timescale 1ns/1ps

module apb_subsystem_tb;

    localparam integer UART_CLK_PER_BIT = 4;

    logic clk;
    logic rst;

    // ============================================================
    // APB MASTER SIGNALS
    // ============================================================

    logic        psel;
    logic        penable;
    logic        pwrite;
    logic [11:0] paddr;
    logic [31:0] pwdata;

    logic [31:0] prdata;
    logic        pready;

    // ============================================================
    // PERIPHERAL OUTPUTS
    // ============================================================

    wire       uart_tx;
    wire [7:0] gpio_out;

    // ============================================================
    // VERIFICATION COUNTERS
    // ============================================================

    integer total_checks;
    integer passed_checks;
    integer failed_checks;

    integer apb_write_checks;
    integer apb_read_checks;
    integer decode_checks;
    integer uart_checks;
    integer timer_checks;
    integer gpio_checks;
    integer invalid_checks;

    // ============================================================
    // DUT
    // ============================================================

    apb_subsystem #(
        .UART_CLK_PER_BIT(UART_CLK_PER_BIT)
    ) dut (
        .clk      (clk),
        .rst      (rst),

        .psel     (psel),
        .penable  (penable),
        .pwrite   (pwrite),
        .paddr    (paddr),
        .pwdata   (pwdata),

        .prdata   (prdata),
        .pready   (pready),

        .uart_tx  (uart_tx),
        .gpio_out (gpio_out)
    );


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    // ============================================================
    // GENERIC CHECK
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

        input [11:0] address;
        input [31:0] data;

        begin

            // ------------------------------
            // SETUP PHASE
            // ------------------------------

            @(posedge clk);

            psel    <= 1'b1;
            penable <= 1'b0;
            pwrite  <= 1'b1;
            paddr   <= address;
            pwdata  <= data;

            // ------------------------------
            // ACCESS PHASE
            // ------------------------------

            @(posedge clk);

            penable <= 1'b1;

            // All valid peripherals respond immediately.
            while (!pready)
                @(posedge clk);

            #1;

            // ------------------------------
            // RETURN TO IDLE
            // ------------------------------

            @(posedge clk);

            psel    <= 1'b0;
            penable <= 1'b0;
            pwrite  <= 1'b0;
            paddr   <= 12'h000;
            pwdata  <= 32'h00000000;

            apb_write_checks = apb_write_checks + 1;

        end

    endtask


    // ============================================================
    // APB READ
    // ============================================================

    task automatic apb_read;

        input  [11:0] address;
        output [31:0] data;

        begin

            // ------------------------------
            // SETUP PHASE
            // ------------------------------

            @(posedge clk);

            psel    <= 1'b1;
            penable <= 1'b0;
            pwrite  <= 1'b0;
            paddr   <= address;
            pwdata  <= 32'h00000000;

            // ------------------------------
            // ACCESS PHASE
            // ------------------------------

            @(posedge clk);

            penable <= 1'b1;

            while (!pready)
                @(posedge clk);

            #1;

            data = prdata;

            // ------------------------------
            // RETURN TO IDLE
            // ------------------------------

            @(posedge clk);

            psel    <= 1'b0;
            penable <= 1'b0;
            pwrite  <= 1'b0;
            paddr   <= 12'h000;

            apb_read_checks = apb_read_checks + 1;

        end

    endtask


    // ============================================================
    // ADDRESS DECODE CHECK
    // ============================================================

    task automatic check_decode;

        input [11:0] address;
        input integer expected_uart;
        input integer expected_timer;
        input integer expected_gpio;

        begin

            // SETUP phase
            @(posedge clk);

            psel    <= 1'b1;
            penable <= 1'b0;
            pwrite  <= 1'b0;
            paddr   <= address;
            pwdata  <= 32'h00000000;

            #1;

            total_checks = total_checks + 1;

            if (
                (dut.uart_sel  === expected_uart) &&
                (dut.timer_sel === expected_timer) &&
                (dut.gpio_sel  === expected_gpio)
            ) begin

                passed_checks = passed_checks + 1;
                decode_checks = decode_checks + 1;

                $display(
                    "PASS: ADDRESS DECODE | ADDR = %03h | UART=%0d TIMER=%0d GPIO=%0d",
                    address,
                    dut.uart_sel,
                    dut.timer_sel,
                    dut.gpio_sel
                );

            end
            else begin

                failed_checks = failed_checks + 1;

                $display(
                    "FAIL: ADDRESS DECODE | ADDR = %03h | UART=%0d TIMER=%0d GPIO=%0d",
                    address,
                    dut.uart_sel,
                    dut.timer_sel,
                    dut.gpio_sel
                );

            end

            // Return to idle
            @(posedge clk);

            psel    <= 1'b0;
            penable <= 1'b0;
            pwrite  <= 1'b0;
            paddr   <= 12'h000;
            pwdata  <= 32'h00000000;

        end

    endtask


    // ============================================================
    // UART TX DONE MONITOR
    // ============================================================

    task automatic wait_uart_done;

        integer timeout;
        integer found_done;

        begin

            timeout = 0;
            found_done = 0;

            while (
                (timeout < 1000) &&
                (found_done == 0)
            ) begin

                @(posedge clk);

                #1;

                if (dut.u_uart.tx_done)
                    found_done = 1;

                timeout = timeout + 1;

            end

            total_checks = total_checks + 1;

            if (found_done) begin

                passed_checks = passed_checks + 1;
                uart_checks = uart_checks + 1;

                $display(
                    "PASS: UART TX DONE detected after %0d cycles",
                    timeout
                );

            end
            else begin

                failed_checks = failed_checks + 1;

                $display(
                    "FAIL: UART TX DONE timeout"
                );

            end

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        // --------------------------------------------------------
        // INITIAL VALUES
        // --------------------------------------------------------

        psel    = 1'b0;
        penable = 1'b0;
        pwrite  = 1'b0;
        paddr   = 12'h000;
        pwdata  = 32'h00000000;

        total_checks = 0;
        passed_checks = 0;
        failed_checks = 0;

        apb_write_checks = 0;
        apb_read_checks  = 0;
        decode_checks    = 0;
        uart_checks      = 0;
        timer_checks     = 0;
        gpio_checks      = 0;
        invalid_checks   = 0;


        // ========================================================
        // HEADER
        // ========================================================

        $display("");
        $display("================================================");
        $display("        APB PERIPHERAL SUBSYSTEM TEST");
        $display("================================================");


        // ========================================================
        // RESET
        // ========================================================

        $display("");
        $display("Applying reset...");

        rst = 1'b1;

        repeat (3)
            @(posedge clk);

        rst = 1'b0;

        repeat (2)
            @(posedge clk);

        $display("Reset released.");


        // ========================================================
        // ADDRESS DECODE TEST
        // ========================================================

        $display("");
        $display("-----------------------------------------------");
        $display("ADDRESS DECODE TEST");
        $display("-----------------------------------------------");

        // UART region
        check_decode(12'h000, 1, 0, 0);
        check_decode(12'h050, 1, 0, 0);
        check_decode(12'h0FF, 1, 0, 0);

        // TIMER region
        check_decode(12'h100, 0, 1, 0);
        check_decode(12'h150, 0, 1, 0);
        check_decode(12'h1FF, 0, 1, 0);

        // GPIO region
        check_decode(12'h200, 0, 0, 1);
        check_decode(12'h250, 0, 0, 1);
        check_decode(12'h2FF, 0, 0, 1);

        // Invalid region
        check_decode(12'h300, 0, 0, 0);


        // ========================================================
        // GPIO TEST
        // ========================================================

        $display("");
        $display("-----------------------------------------------");
        $display("GPIO PERIPHERAL TEST");
        $display("-----------------------------------------------");

        // Write GPIO output
        apb_write(
            12'h200,
            32'h000000A5
        );

        #1;

        check_value(
            {24'h000000, gpio_out},
            32'h000000A5,
            "GPIO OUTPUT WRITE"
        );

        gpio_checks = gpio_checks + 1;


        // Write GPIO direction
        apb_write(
            12'h204,
            32'h000000FF
        );

        begin : gpio_direction_test

            reg [31:0] gpio_direction_value;

            apb_read(
                12'h204,
                gpio_direction_value
            );

            check_value(
                gpio_direction_value,
                32'h000000FF,
                "GPIO DIRECTION REGISTER"
            );

            gpio_checks = gpio_checks + 1;

        end


        // ========================================================
        // TIMER TEST
        // ========================================================

        $display("");
        $display("-----------------------------------------------");
        $display("TIMER PERIPHERAL TEST");
        $display("-----------------------------------------------");

        // Load timer with 10
        apb_write(
            12'h100,
            32'd10
        );

        begin : timer_load_test

            reg [31:0] timer_load_value;

            apb_read(
                12'h100,
                timer_load_value
            );

            check_value(
                timer_load_value,
                32'd10,
                "TIMER LOAD REGISTER"
            );

            timer_checks = timer_checks + 1;

        end


        // Start timer
        apb_write(
            12'h108,
            32'h00000001
        );

        // Give timer one cycle to start
        @(posedge clk);
        #1;


        // Check timer is running
        begin : timer_enable_test

            reg [31:0] timer_enable_value;

            apb_read(
                12'h108,
                timer_enable_value
            );

            check_value(
                timer_enable_value,
                32'h00000001,
                "TIMER ENABLE REGISTER"
            );

            timer_checks = timer_checks + 1;

        end


        // Wait long enough for completion
        repeat (15)
            @(posedge clk);

        #1;


        // Check DONE
        begin : timer_done_test

            reg [31:0] timer_done_value;

            apb_read(
                12'h10C,
                timer_done_value
            );

            check_value(
                timer_done_value,
                32'h00000001,
                "TIMER DONE"
            );

            timer_checks = timer_checks + 1;

        end


        // ========================================================
        // UART TEST
        // ========================================================

        $display("");
        $display("-----------------------------------------------");
        $display("UART PERIPHERAL TEST");
        $display("-----------------------------------------------");

        // Write UART data
        apb_write(
            12'h000,
            32'h00000055
        );

        // Wait for UART transmission
        wait_uart_done();


        // Read UART DATA register
        begin : uart_data_test

            reg [31:0] uart_data_value;

            apb_read(
                12'h000,
                uart_data_value
            );

            check_value(
                uart_data_value,
                32'h00000055,
                "UART DATA REGISTER"
            );

            uart_checks = uart_checks + 1;

        end


        // Read UART STATUS register
        begin : uart_status_test

            reg [31:0] uart_status_value;

            apb_read(
                12'h004,
                uart_status_value
            );

            check_value(
                uart_status_value,
                32'h00000000,
                "UART STATUS IDLE"
            );

            uart_checks = uart_checks + 1;

        end


        // ========================================================
        // PERIPHERAL ISOLATION
        // ========================================================

        $display("");
        $display("-----------------------------------------------");
        $display("PERIPHERAL ISOLATION TEST");
        $display("-----------------------------------------------");


        // GPIO write must not modify TIMER
        apb_write(
            12'h200,
            32'h0000005A
        );

        begin : timer_isolation_test

            reg [31:0] timer_load_after_gpio;

            apb_read(
                12'h100,
                timer_load_after_gpio
            );

            check_value(
                timer_load_after_gpio,
                32'd10,
                "GPIO DOES NOT ALTER TIMER"
            );

        end


        // TIMER write must not modify GPIO
        apb_write(
            12'h100,
            32'd7
        );

        begin : gpio_isolation_test

            reg [31:0] gpio_after_timer;

            apb_read(
                12'h200,
                gpio_after_timer
            );

            check_value(
                gpio_after_timer,
                32'h0000005A,
                "TIMER DOES NOT ALTER GPIO"
            );

        end


        // ========================================================
        // INVALID ADDRESS RESPONSE TEST
        // ========================================================

        $display("");
        $display("-----------------------------------------------");
        $display("INVALID ADDRESS TEST");
        $display("-----------------------------------------------");

        begin : invalid_address_test

            integer invalid_cycle;

            // SETUP
            @(posedge clk);

            psel    <= 1'b1;
            penable <= 1'b0;
            pwrite  <= 1'b0;
            paddr   <= 12'h300;
            pwdata  <= 32'h00000000;

            // ACCESS
            @(posedge clk);

            penable <= 1'b1;

            // Check that no peripheral responds
            for (
                invalid_cycle = 0;
                invalid_cycle < 3;
                invalid_cycle = invalid_cycle + 1
            ) begin

                #1;

                total_checks = total_checks + 1;

                if (!pready) begin

                    passed_checks = passed_checks + 1;
                    invalid_checks = invalid_checks + 1;

                    $display(
                        "PASS: INVALID ADDRESS %03h | PREADY = 0",
                        12'h300
                    );

                end
                else begin

                    failed_checks = failed_checks + 1;

                    $display(
                        "FAIL: INVALID ADDRESS %03h | PREADY = 1",
                        12'h300
                    );

                end

                @(posedge clk);

            end

            // Return to idle
            psel    <= 1'b0;
            penable <= 1'b0;
            pwrite  <= 1'b0;
            paddr   <= 12'h000;
            pwdata  <= 32'h00000000;

        end


        // ========================================================
        // FINAL VERIFICATION
        // ========================================================

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display("");
        $display("APB WRITE CHECKS     = %0d", apb_write_checks);
        $display("APB READ CHECKS      = %0d", apb_read_checks);
        $display("DECODE CHECKS        = %0d", decode_checks);
        $display("UART CHECKS          = %0d", uart_checks);
        $display("TIMER CHECKS         = %0d", timer_checks);
        $display("GPIO CHECKS          = %0d", gpio_checks);
        $display("INVALID CHECKS       = %0d", invalid_checks);

        $display("");
        $display("TOTAL CHECKS         = %0d", total_checks);
        $display("PASSED CHECKS        = %0d", passed_checks);
        $display("FAILED CHECKS        = %0d", failed_checks);

        $display("");

        if (failed_checks == 0)
            $display("OVERALL RESULT = PASS");
        else
            $display("OVERALL RESULT = FAIL");

        $display("================================================");

        $finish;

    end

endmodule