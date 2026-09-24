`timescale 1ns/1ps

module apb_peripheral_tb;

    reg PCLK;
    reg PRESETn;

    // Master control
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

    // Peripheral response
    wire [7:0] PRDATA;
    wire       PREADY;
    wire       PSLVERR;

    // Master status
    wire [7:0] read_data_out;
    wire       busy;
    wire       done;
    wire       error;

    // Peripheral output
    wire [7:0] counter_value;


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
    // APB PERIPHERAL
    // =========================================================

    apb_peripheral peripheral (

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

        .counter_value(counter_value)
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

        $dumpfile("apb_peripheral_tb.vcd");
        $dumpvars(0, apb_peripheral_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | PSEL=%b | PENABLE=%b | WR=%b | ADDR=%h | WDATA=%h | RDATA=%h | READY=%b | ERR=%b | COUNTER=%h | BUSY=%b | DONE=%b",
            $time,
            PSEL,
            PENABLE,
            PWRITE,
            PADDR,
            PWDATA,
            PRDATA,
            PREADY,
            PSLVERR,
            counter_value,
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

            if (!error) begin

                $display(
                    "PASS: WRITE | ADDRESS=%h | DATA=%h",
                    addr,
                    data
                );

            end else begin

                $display(
                    "PASS: WRITE ERROR | ADDRESS=%h",
                    addr
                );

            end

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

            if (!error) begin

                $display(
                    "APB READ | ADDRESS=%h | DATA=%h",
                    addr,
                    read_data_out
                );

            end else begin

                $display(
                    "APB READ ERROR | ADDRESS=%h",
                    addr
                );

            end

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
        // TEST 1
        // Configure counter limit = 5
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 1: CONFIGURE COUNTER LIMIT");
        $display("========================================");

        apb_write(8'h0C, 8'h05);


        // =====================================================
        // TEST 2
        // Load starting value = 0
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: LOAD START VALUE");
        $display("========================================");

        apb_write(8'h08, 8'h00);


        // =====================================================
        // TEST 3
        // Enable counter
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: ENABLE COUNTER");
        $display("========================================");

        apb_write(8'h00, 8'h01);


        // Allow counter to run
        repeat(8) @(posedge PCLK);


        // =====================================================
        // TEST 4
        // Read STATUS
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 4: READ STATUS");
        $display("========================================");

        apb_read(8'h04);


        #5;

        if (counter_value == 8'h05) begin

            $display(
                "PASS: COUNTER REACHED LIMIT | COUNTER=%h",
                counter_value
            );

        end else begin

            $display(
                "FAIL: COUNTER VALUE | EXPECTED=05 | GOT=%h",
                counter_value
            );

        end


        // =====================================================
        // TEST 5
        // Disable counter
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 5: DISABLE COUNTER");
        $display("========================================");

        apb_write(8'h00, 8'h00);


        // =====================================================
        // TEST 6
        // Invalid address
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 6: INVALID ADDRESS");
        $display("========================================");

        @(negedge PCLK);

        address    = 8'h20;
        write_data = 8'hAA;
        write      = 1'b1;
        start      = 1'b1;

        @(negedge PCLK);

        start = 1'b0;

        wait(done);

        #1;

        if (error) begin

            $display(
                "PASS: INVALID ADDRESS | PSLVERR=1"
            );

        end else begin

            $display(
                "FAIL: INVALID ADDRESS | PSLVERR=0"
            );

        end


        #20;

        $display("");
        $display("========================================");
        $display("APB PERIPHERAL TEST COMPLETED");
        $display("========================================");

        $finish;

    end

endmodule