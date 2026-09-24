`timescale 1ns/1ps

module apb_master_slave_tb;

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

    // Slave response
    wire [7:0]  PRDATA;
    wire        PREADY;
    wire        PSLVERR;

    // Master result
    wire [7:0]  read_data_out;
    wire        busy;
    wire        done;
    wire        error;


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
    // APB SLAVE
    // =========================================================

    apb_slave slave (

        .PCLK(PCLK),
        .PRESETn(PRESETn),

        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),

        .PRDATA(PRDATA),
        .PREADY(PREADY),
        .PSLVERR(PSLVERR)
    );


    // =========================================================
    // CLOCK
    // =========================================================

    initial begin
        PCLK = 1'b0;

        forever #5 PCLK = ~PCLK;
    end


    // =========================================================
    // WAVEFORM
    // =========================================================

    initial begin
        $dumpfile("apb_master_slave_tb.vcd");
        $dumpvars(0, apb_master_slave_tb);
    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | PSEL=%b | PENABLE=%b | PWRITE=%b | PADDR=%h | PWDATA=%h | PRDATA=%h | PREADY=%b | ERR=%b | BUSY=%b | DONE=%b",
            $time,
            PSEL,
            PENABLE,
            PWRITE,
            PADDR,
            PWDATA,
            PRDATA,
            PREADY,
            PSLVERR,
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

            address   = addr;
            write_data = data;
            write     = 1'b1;
            start     = 1'b1;

            @(negedge PCLK);

            start = 1'b0;

            wait(done);

            #1;

            if (!error) begin

                $display(
                    "PASS: APB WRITE | ADDRESS=%h | DATA=%h",
                    addr,
                    data
                );

            end else begin

                $display(
                    "FAIL: APB WRITE ERROR | ADDRESS=%h | DATA=%h",
                    addr,
                    data
                );

            end

        end

    endtask


    // =========================================================
    // READ TASK
    // =========================================================

    task apb_read;

        input [7:0] addr;
        input [7:0] expected;

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

            if (!error && read_data_out == expected) begin

                $display(
                    "PASS: APB READ | ADDRESS=%h | DATA=%h",
                    addr,
                    read_data_out
                );

            end else begin

                $display(
                    "FAIL: APB READ | ADDRESS=%h | EXPECTED=%h | GOT=%h",
                    addr,
                    expected,
                    read_data_out
                );

            end

        end

    endtask


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        // Initial values
        PRESETn   = 1'b0;

        start     = 1'b0;
        write     = 1'b0;
        address   = 8'h00;
        write_data = 8'h00;


        // Reset
        #20;

        PRESETn = 1'b1;

        #20;


        // -----------------------------------------------------
        // TEST 1
        // -----------------------------------------------------

        $display("");
        $display("========================================");
        $display("TEST 1: WRITE + READ REG0");
        $display("========================================");

        apb_write(8'h00, 8'hA5);

        apb_read(8'h00, 8'hA5);


        // -----------------------------------------------------
        // TEST 2
        // -----------------------------------------------------

        $display("");
        $display("========================================");
        $display("TEST 2: WRITE + READ REG1");
        $display("========================================");

        apb_write(8'h04, 8'h3C);

        apb_read(8'h04, 8'h3C);


        // -----------------------------------------------------
        // TEST 3
        // -----------------------------------------------------

        $display("");
        $display("========================================");
        $display("TEST 3: WRITE + READ REG2");
        $display("========================================");

        apb_write(8'h08, 8'hF0);

        apb_read(8'h08, 8'hF0);


        // -----------------------------------------------------
        // TEST 4: INVALID ADDRESS
        // -----------------------------------------------------

        $display("");
        $display("========================================");
        $display("TEST 4: INVALID ADDRESS");
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

        if (error) begin

            $display(
                "PASS: APB INVALID ADDRESS | ADDRESS=%h | PSLVERR=1",
                address
            );

        end else begin

            $display(
                "FAIL: APB INVALID ADDRESS | PSLVERR=0"
            );

        end


        #20;

        $display("");
        $display("========================================");
        $display("APB MASTER + SLAVE TEST COMPLETED");
        $display("========================================");

        $finish;

    end

endmodule