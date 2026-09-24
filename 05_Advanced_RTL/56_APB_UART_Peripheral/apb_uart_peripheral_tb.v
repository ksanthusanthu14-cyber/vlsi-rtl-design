`timescale 1ns/1ps

module apb_uart_peripheral_tb;

    reg PCLK;
    reg PRESETn;

    // APB master controls
    reg        start;
    reg        write;
    reg [7:0]  address;
    reg [7:0]  write_data;

    // APB bus
    wire        PSEL;
    wire        PENABLE;
    wire        PWRITE;
    wire [7:0]  PADDR;
    wire [7:0]  PWDATA;

    wire [7:0] PRDATA;
    wire       PREADY;
    wire       PSLVERR;

    wire [7:0] read_data_out;
    wire       busy;
    wire       done;
    wire       error;

    // UART
    wire tx;
    wire rx;

    // Loopback
    assign rx = tx;


    // =========================================================
    // APB MASTER
    // =========================================================

    apb_master master (

        .PCLK(PCLK),
        .PRESETn(PRESETn),

        .start(start),
        .write(write),
        .address(address),
        .write_data(write_data),

        .read_data(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),

        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),

        .read_data_out(read_data_out),
        .busy(busy),
        .done(done),
        .error(error)
    );


    // =========================================================
    // UART PERIPHERAL
    // =========================================================

    apb_uart_peripheral uart (

        .PCLK(PCLK),
        .PRESETn(PRESETn),

        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),

        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR),

        .rx(rx),
        .tx(tx)
    );


    // =========================================================
    // CLOCK
    // =========================================================

    initial begin

        PCLK = 1'b0;

        forever #5 PCLK = ~PCLK;

    end


    // =========================================================
    // VCD
    // =========================================================

    initial begin

        $dumpfile("apb_uart_peripheral_tb.vcd");
        $dumpvars(0, apb_uart_peripheral_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | PSEL=%b | PENABLE=%b | WR=%b | ADDR=%h | WDATA=%h | RDATA=%h | READY=%b | ERR=%b | TX=%b | RX=%b | BUSY=%b | DONE=%b",
            $time,
            PSEL,
            PENABLE,
            PWRITE,
            PADDR,
            PWDATA,
            PRDATA,
            PREADY,
            PSLVERR,
            tx,
            rx,
            busy,
            done
        );

    end


    // =========================================================
    // WRITE TASK
    // =========================================================

    task apb_write;

        input [7:0] addr;
        input [7:0] data;

        begin

            @(negedge PCLK);

            address    = addr;
            write_data = data;
            write      = 1'b1;
            start      = 1'b1;

            @(negedge PCLK);

            start = 1'b0;

            wait(done);

            #1;

            if (!error)

                $display(
                    "PASS: APB WRITE | ADDRESS=%h | DATA=%h",
                    addr,
                    data
                );

            else

                $display(
                    "FAIL: APB WRITE | ADDRESS=%h",
                    addr
                );

        end

    endtask


    // =========================================================
    // READ TASK
    // =========================================================

    task apb_read;

        input [7:0] addr;

        begin

            @(negedge PCLK);

            address    = addr;
            write_data = 8'h00;
            write      = 1'b0;
            start      = 1'b1;

            @(negedge PCLK);

            start = 1'b0;

            wait(done);

            #1;

            if (!error)

                $display(
                    "APB READ | ADDRESS=%h | DATA=%h",
                    addr,
                    read_data_out
                );

            else

                $display(
                    "APB READ ERROR | ADDRESS=%h",
                    addr
                );

        end

    endtask


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        PRESETn    = 1'b0;

        start      = 1'b0;
        write      = 1'b0;
        address    = 8'h00;
        write_data = 8'h00;


        // RESET
        #20;

        PRESETn = 1'b1;

        #20;


        // =====================================================
        // TEST 1: BAUD CONFIGURATION
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 1: BAUD CONFIGURATION");
        $display("========================================");

        apb_write(8'h10, 8'h04);


        // =====================================================
        // TEST 2: ENABLE UART
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: ENABLE UART");
        $display("========================================");

        apb_write(8'h00, 8'h01);


        // =====================================================
        // TEST 3: WRITE TX DATA
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: UART LOOPBACK");
        $display("========================================");

        apb_write(8'h08, 8'hA5);


        // Allow complete UART transmission
        // 10 bits × 4 clocks/bit
        repeat(60) @(posedge PCLK);


        // =====================================================
        // TEST 4: READ RX DATA
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 4: READ RX DATA");
        $display("========================================");

        apb_read(8'h0C);


        #1;

        if (read_data_out == 8'hA5) begin

            $display(
                "PASS: UART LOOPBACK | TX=A5 | RX=A5"
            );

        end else begin

            $display(
                "FAIL: UART LOOPBACK | TX=A5 | RX=%h",
                read_data_out
            );

        end


        // =====================================================
        // TEST 5: SECOND BYTE
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 5: SECOND UART BYTE");
        $display("========================================");

        apb_write(8'h08, 8'h3C);

        repeat(60) @(posedge PCLK);

        apb_read(8'h0C);

        #1;

        if (read_data_out == 8'h3C)

            $display(
                "PASS: UART LOOPBACK | TX=3C | RX=3C"
            );

        else

            $display(
                "FAIL: UART LOOPBACK | TX=3C | RX=%h",
                read_data_out
            );


        // =====================================================
        // TEST 6: STATUS
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 6: STATUS REGISTER");
        $display("========================================");

        apb_read(8'h04);


        // =====================================================
        // TEST 7: INVALID ADDRESS
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 7: INVALID ADDRESS");
        $display("========================================");

        @(negedge PCLK);

        address    = 8'h20;
        write_data = 8'h55;
        write      = 1'b1;
        start      = 1'b1;

        @(negedge PCLK);

        start = 1'b0;

        wait(done);

        #1;

        if (error)

            $display(
                "PASS: INVALID ADDRESS | PSLVERR=1"
            );

        else

            $display(
                "FAIL: INVALID ADDRESS | PSLVERR=0"
            );


        #20;

        $display("");
        $display("========================================");
        $display("APB UART PERIPHERAL TEST COMPLETED");
        $display("========================================");

        $finish;

    end

endmodule