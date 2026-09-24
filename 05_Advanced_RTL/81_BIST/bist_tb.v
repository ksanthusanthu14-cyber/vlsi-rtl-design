`timescale 1ns/1ps

module bist_tb;

    localparam WIDTH = 4;
    localparam SEED  = 4'b0001;

    // CORRECT GOLDEN SIGNATURE
    localparam GOLDEN_SIGNATURE = 4'b1010;

    reg clk;
    reg rst;
    reg start;
    reg fault_inject;

    wire busy;
    wire done;
    wire pass;

    wire [WIDTH-1:0] test_pattern;
    wire [WIDTH-1:0] signature;


    //==================================================
    // DUT
    //==================================================

    bist #(
        .WIDTH(WIDTH),
        .SEED(SEED),
        .GOLDEN_SIGNATURE(GOLDEN_SIGNATURE)
    ) dut (

        .clk(clk),
        .rst(rst),
        .start(start),
        .fault_inject(fault_inject),

        .busy(busy),
        .done(done),
        .pass(pass),

        .test_pattern(test_pattern),
        .signature(signature)
    );


    //==================================================
    // CLOCK
    //==================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end


    //==================================================
    // TESTS
    //==================================================

    initial begin

        $dumpfile("bist.vcd");
        $dumpvars(0, bist_tb);


        // Initial conditions
        rst = 1'b1;
        start = 1'b0;
        fault_inject = 1'b0;


        // Reset
        #12;
        rst = 1'b0;


        //==================================================
        // TEST 1: HEALTHY CIRCUIT
        //==================================================

        $display("");
        $display("==============================================");
        $display("TEST 1: HEALTHY CIRCUIT");
        $display("==============================================");

        start = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;

        wait(done == 1'b1);

        #1;

        $display("HEALTHY SIGNATURE = %b", signature);

        if (signature === GOLDEN_SIGNATURE)
            $display("PASS: GOLDEN SIGNATURE MATCHED");
        else
            $display("FAIL: GOLDEN SIGNATURE MISMATCH");


        if (pass === 1'b1)
            $display("PASS: HEALTHY CIRCUIT PASSED BIST");
        else
            $display("FAIL: HEALTHY CIRCUIT REPORTED FAIL");


        //==================================================
        // TEST 2: FAULT INJECTION
        //==================================================

        @(posedge clk);

        fault_inject = 1'b1;


        $display("");
        $display("==============================================");
        $display("TEST 2: FAULT INJECTION");
        $display("==============================================");


        start = 1'b1;

        @(posedge clk);
        #1;

        start = 1'b0;

        wait(done == 1'b1);

        #1;

        $display("FAULTY SIGNATURE = %b", signature);


        if (signature !== GOLDEN_SIGNATURE)
            $display("PASS: FAULT DETECTED");
        else
            $display("FAIL: FAULT WAS NOT DETECTED");


        if (pass === 1'b0)
            $display("PASS: FAULTY CIRCUIT FAILED BIST");
        else
            $display("FAIL: FAULTY CIRCUIT PASSED BIST");


        //==================================================
        // COMPLETE
        //==================================================

        $display("");
        $display("==============================================");
        $display("BIST VERIFICATION COMPLETE");
        $display("==============================================");

        $finish;

    end

endmodule