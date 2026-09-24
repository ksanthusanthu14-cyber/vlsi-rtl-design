`timescale 1ns/1ps

module alu_tb;

    reg [7:0] a;
    reg [7:0] b;
    reg [2:0] op;

    wire [7:0] result;

    alu dut (
        .a      (a),
        .b      (b),
        .op     (op),
        .result (result)
    );


    // Verification components
    alu_sequencer sequencer;
    alu_driver    driver;
    alu_monitor   monitor;
    alu_scoreboard scoreboard;


    alu_transaction tr;

    integer i;


    initial begin

        $dumpfile("uvm_alu.vcd");
        $dumpvars(0, alu_tb);


        // Initial values
        a  = 8'h00;
        b  = 8'h00;
        op = 3'b000;


        // Create verification components
        sequencer  = new;
        driver     = new;
        monitor    = new;
        scoreboard = new;


        $display("");
        $display("======================================");
        $display("UVM-STYLE ALU TEST START");
        $display("======================================");


        // 100 randomized transactions
        for (i = 0; i < 100; i = i + 1) begin

            // -------------------------------
            // SEQUENCER
            // -------------------------------
            sequencer.get_next_transaction(tr);


            // -------------------------------
            // DRIVER
            // -------------------------------
            driver.drive(
                tr.a,
                tr.b,
                tr.op
            );


            // -------------------------------
            // DUT
            // -------------------------------
            a  = tr.a;
            b  = tr.b;
            op = tr.op;


            // Allow combinational logic to settle
            #1;


            // -------------------------------
            // MONITOR
            // -------------------------------
            monitor.sample(
                a,
                b,
                op,
                result
            );


            // -------------------------------
            // SCOREBOARD
            // -------------------------------
            scoreboard.check(
                a,
                b,
                op,
                result
            );

        end


        // -------------------------------
        // FINAL REPORT
        // -------------------------------
        scoreboard.report;


        #10;

        $finish;

    end

endmodule