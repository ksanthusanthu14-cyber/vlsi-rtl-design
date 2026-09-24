`timescale 1ns/1ps

module cpu_8bit_tb;

    reg clk;
    reg rst;

    wire [7:0] accumulator;
    wire [3:0] pc;
    wire [7:0] output_data;
    wire halted;


    // =========================================================
    // DUT
    // =========================================================

    cpu_8bit uut (

        .clk(clk),
        .rst(rst),

        .accumulator(accumulator),
        .pc(pc),
        .output_data(output_data),
        .halted(halted)

    );


    // =========================================================
    // CLOCK
    // =========================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // =========================================================
    // WAVEFORM
    // =========================================================

    initial begin

        $dumpfile("8_bit_cpu.vcd");

        $dumpvars(0, cpu_8bit_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    always @(posedge clk) begin

        #1;

        $display(
            "TIME=%0t | PC=%0d | INSTR=%b | ACC=%0d | OUT=%0d | HALT=%b",
            $time,
            pc,
            uut.instruction,
            accumulator,
            output_data,
            halted
        );

    end


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        rst = 1'b1;

        #12;

        rst = 1'b0;


        // -----------------------------------------------------
        // WAIT FOR CPU TO HALT
        // -----------------------------------------------------

        wait (halted == 1'b1);

        #10;


        // -----------------------------------------------------
        // TEST 1: ACCUMULATOR
        // -----------------------------------------------------

        if (accumulator == 8'd14)

            $display(
                "PASS: FINAL ACCUMULATOR = 14"
            );

        else

            $display(
                "FAIL: EXPECTED ACCUMULATOR = 14, GOT %0d",
                accumulator
            );


        // -----------------------------------------------------
        // TEST 2: OUTPUT
        // -----------------------------------------------------

        if (output_data == 8'd14)

            $display(
                "PASS: OUTPUT = 14"
            );

        else

            $display(
                "FAIL: EXPECTED OUTPUT = 14, GOT %0d",
                output_data
            );


        // -----------------------------------------------------
        // TEST 3: HALT
        // -----------------------------------------------------

        if (halted == 1'b1)

            $display(
                "PASS: CPU HALTED"
            );

        else

            $display(
                "FAIL: CPU DID NOT HALT"
            );


        // -----------------------------------------------------
        // FINAL RESULT
        // -----------------------------------------------------

        if (
            accumulator == 8'd14 &&
            output_data == 8'd14 &&
            halted == 1'b1
        ) begin

            $display("");
            $display("==============================================");
            $display("ALL 8-BIT CPU TESTS PASSED");
            $display("==============================================");

        end

        else begin

            $display("");
            $display("==============================================");
            $display("8-BIT CPU TEST FAILED");
            $display("==============================================");

        end


        #10;

        $finish;

    end

endmodule