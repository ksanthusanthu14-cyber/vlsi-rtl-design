`timescale 1ns/1ps

module setup_tb;

    // ========================================================
    // TIMING PARAMETERS
    // ========================================================

    parameter integer TCLK   = 10;
    parameter integer TCQ    = 1;
    parameter integer TCOMB  = 3;
    parameter integer TSETUP = 1;

    // ========================================================
    // SIGNALS
    // ========================================================

    logic clk;
    logic rst;
    logic d;

    logic launch_q;
    logic data_arrival;
    logic capture_q;


    // ========================================================
    // DUT
    // ========================================================

    setup_path #(
        .TCQ(TCQ),
        .TCOMB(TCOMB),
        .TSETUP(TSETUP)
    ) dut (

        .clk(clk),
        .rst(rst),
        .d(d),

        .launch_q(launch_q),
        .data_arrival(data_arrival),
        .capture_q(capture_q)

    );


    // ========================================================
    // CLOCK
    // ========================================================

    initial begin

        clk = 1'b0;

        forever #(TCLK/2) clk = ~clk;

    end


    // ========================================================
    // VCD
    // ========================================================

    initial begin

        $dumpfile("setup_analysis.vcd");

        $dumpvars(0, setup_tb);

    end


    // ========================================================
    // TIMING VARIABLES
    // ========================================================

    integer required_time;
    integer arrival_time;
    integer setup_slack;

    integer passed;
    integer failed;


    // ========================================================
    // TEST
    // ========================================================

    initial begin

        passed = 0;
        failed = 0;

        rst = 1'b1;
        d   = 1'b0;

        // ----------------------------------------------------
        // Reset
        // ----------------------------------------------------

        repeat (2)
            @(posedge clk);

        #1;

        rst = 1'b0;

        // ----------------------------------------------------
        // Calculate setup timing
        // ----------------------------------------------------

        required_time = TCLK;

        arrival_time = TCQ + TCOMB + TSETUP;

        setup_slack = required_time - arrival_time;


        // ====================================================
        // TIMING REPORT
        // ====================================================

        $display("");
        $display("================================================");
        $display("       PROJECT 106 - SETUP TIME ANALYSIS");
        $display("================================================");

        $display("");

        $display("TIMING PARAMETERS");
        $display("-----------------");

        $display("Clock Period       = %0d ns", TCLK);
        $display("Clock-to-Q Delay   = %0d ns", TCQ);
        $display("Combinational Delay= %0d ns", TCOMB);
        $display("Setup Time         = %0d ns", TSETUP);

        $display("");

        $display("TIMING CALCULATION");
        $display("------------------");

        $display(
            "Arrival Requirement = Tcq + Tcomb + Tsetup"
        );

        $display(
            "Arrival Requirement = %0d + %0d + %0d",
            TCQ,
            TCOMB,
            TSETUP
        );

        $display(
            "Arrival Requirement = %0d ns",
            arrival_time
        );

        $display("");

        $display(
            "Required Time = %0d ns",
            required_time
        );

        $display(
            "Setup Slack = Required Time - Arrival Requirement"
        );

        $display(
            "Setup Slack = %0d - %0d",
            required_time,
            arrival_time
        );

        $display(
            "Setup Slack = %0d ns",
            setup_slack
        );


        // ====================================================
        // SETUP CHECK
        // ====================================================

        $display("");
        $display("SETUP CHECK");
        $display("-----------");

        if (setup_slack > 0) begin

            $display(
                "PASS: POSITIVE SETUP SLACK = %0d ns",
                setup_slack
            );

            passed = passed + 1;

        end

        else if (setup_slack == 0) begin

            $display(
                "PASS: ZERO SLACK - TIMING BOUNDARY"
            );

            passed = passed + 1;

        end

        else begin

            $display(
                "EXPECTED VIOLATION: NEGATIVE SLACK = %0d ns",
                setup_slack
            );

        end


        // ====================================================
        // WAVEFORM ACTIVITY
        // ====================================================

        $display("");
        $display("SIMULATION ACTIVITY");
        $display("--------------------");

        d = 1'b1;

        @(posedge clk);

        #1;

        $display(
            "Launch Q       = %b",
            launch_q
        );

        #TCQ;

        $display(
            "Data Path      = %b",
            data_arrival
        );

        @(posedge clk);

        #1;

        $display(
            "Capture Q      = %b",
            capture_q
        );


        // ====================================================
        // FINAL RESULT
        // ====================================================

        $display("");
        $display("================================================");
        $display("             FINAL VERIFICATION");
        $display("================================================");

        $display(
            "CLOCK PERIOD    = %0d ns",
            TCLK
        );

        $display(
            "DATA PATH DELAY = %0d ns",
            TCQ + TCOMB
        );

        $display(
            "SETUP TIME      = %0d ns",
            TSETUP
        );

        $display(
            "SETUP SLACK     = %0d ns",
            setup_slack
        );

        $display(
            "PASSED CHECKS   = %0d",
            passed
        );

        $display(
            "FAILED CHECKS   = %0d",
            failed
        );


        if (setup_slack >= 0) begin

            $display("");
            $display("OVERALL RESULT = PASS");

        end
        else begin

            $display("");
            $display("OVERALL RESULT = EXPECTED SETUP VIOLATION");

        end

        $display("================================================");


        #20;

        $finish;

    end

endmodule