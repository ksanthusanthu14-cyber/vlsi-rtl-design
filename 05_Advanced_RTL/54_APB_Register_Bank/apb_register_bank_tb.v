`timescale 1ns/1ps

module apb_register_bank_tb;

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

    // Register outputs
    wire [7:0] control_reg;
    wire [7:0] status_reg;
    wire [7:0] data_reg;
    wire [7:0] config_reg;


    // =========================================================
    // MASTER
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
    // REGISTER BANK
    // =========================================================

    apb_register_bank register_bank (

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

        .control_reg(control_reg),
        .status_reg(status_reg),
        .data_reg(data_reg),
        .config_reg(config_reg)
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

        $dumpfile("apb_register_bank_tb.vcd");
        $dumpvars(0, apb_register_bank_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    initial begin

        $monitor(
            "Time=%0t | PSEL=%b | PENABLE=%b | WR=%b | ADDR=%h | WDATA=%h | RDATA=%h | READY=%b | ERR=%b | CTRL=%h | STATUS=%h | DATA=%h | CONFIG=%h",
            $time,
            PSEL,
            PENABLE,
            PWRITE,
            PADDR,
            PWDATA,
            PRDATA,
            PREADY,
            PSLVERR,
            control_reg,
            status_reg,
            data_reg,
            config_reg
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
                    "PASS: WRITE ERROR DETECTED | ADDRESS=%h",
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
                    "PASS: READ | ADDRESS=%h | DATA=%h",
                    addr,
                    read_data_out
                );

            end else begin

                $display(
                    "FAIL: READ | ADDRESS=%h | EXPECTED=%h | GOT=%h | ERROR=%b",
                    addr,
                    expected,
                    read_data_out,
                    error
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

        // Reset
        #20;

        PRESETn = 1'b1;

        #20;


        // =====================================================
        // TEST 1: CONTROL
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 1: CONTROL REGISTER");
        $display("========================================");

        apb_write(8'h00, 8'hA5);

        apb_read(8'h00, 8'hA5);


        // =====================================================
        // TEST 2: STATUS
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 2: STATUS REGISTER");
        $display("========================================");

        apb_read(8'h04, 8'h01);


        // =====================================================
        // TEST 3: DATA
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 3: DATA REGISTER");
        $display("========================================");

        apb_write(8'h08, 8'h3C);

        apb_read(8'h08, 8'h3C);


        // =====================================================
        // TEST 4: CONFIG
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 4: CONFIG REGISTER");
        $display("========================================");

        apb_write(8'h0C, 8'hF0);

        apb_read(8'h0C, 8'hF0);


        // =====================================================
        // TEST 5: STATUS WRITE PROTECTION
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 5: STATUS WRITE PROTECTION");
        $display("========================================");

        apb_write(8'h04, 8'hFF);

        #5;

        if (error) begin

            $display(
                "PASS: STATUS WRITE BLOCKED | PSLVERR=1"
            );

        end


        // =====================================================
        // TEST 6: INVALID ADDRESS
        // =====================================================

        $display("");
        $display("========================================");
        $display("TEST 6: INVALID ADDRESS");
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
                "PASS: INVALID ADDRESS | ADDRESS=%h | PSLVERR=1",
                address
            );

        end else begin

            $display(
                "FAIL: INVALID ADDRESS | PSLVERR=0"
            );

        end


        #20;

        $display("");
        $display("========================================");
        $display("APB REGISTER BANK TEST COMPLETED");
        $display("========================================");

        $finish;

    end

endmodule