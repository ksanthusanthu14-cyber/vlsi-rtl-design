`timescale 1ns/1ps

module cpu_8bit_single_cycle_tb;

    reg clk;
    reg rst;

    wire [7:0] accumulator;
    wire [3:0] pc;
    wire [7:0] output_data;
    wire halted;


    // =========================================================
    // DUT
    // =========================================================

    cpu_8bit_single_cycle uut (

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
    // VCD
    // =========================================================

    initial begin

        $dumpfile("8_bit_single_cycle_cpu.vcd");

        $dumpvars(0, cpu_8bit_single_cycle_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    always @(posedge clk) begin

        #1;

        $display(
            "TIME=%0t | PC=%0d | INSTR=%b | R0=%0d | R1=%0d | R2=%0d | R3=%0d | MEM1=%0d | OUT=%0d | HALT=%b",
            $time,
            pc,
            uut.instruction,
            uut.registers[0],
            uut.registers[1],
            uut.registers[2],
            uut.registers[3],
            uut.data_memory[1],
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
        // WAIT FOR CPU
        // -----------------------------------------------------

        wait (halted == 1'b1);

        #10;


        // -----------------------------------------------------
        // TEST R0
        // -----------------------------------------------------

        if (uut.registers[0] == 8'd12)

            $display(
                "PASS: R0 = 12"
            );

        else

            $display(
                "FAIL: EXPECTED R0 = 12, GOT %0d",
                uut.registers[0]
            );


        // -----------------------------------------------------
        // TEST R1
        // -----------------------------------------------------

        if (uut.registers[1] == 8'd5)

            $display(
                "PASS: R1 = 5"
            );

        else

            $display(
                "FAIL: EXPECTED R1 = 5, GOT %0d",
                uut.registers[1]
            );


        // -----------------------------------------------------
        // TEST R2
        // -----------------------------------------------------

        if (uut.registers[2] == 8'd25)

            $display(
                "PASS: R2 = 25"
            );

        else

            $display(
                "FAIL: EXPECTED R2 = 25, GOT %0d",
                uut.registers[2]
            );


        // -----------------------------------------------------
        // TEST R3
        // -----------------------------------------------------

        if (uut.registers[3] == 8'd25)

            $display(
                "PASS: R3 = 25"
            );

        else

            $display(
                "FAIL: EXPECTED R3 = 25, GOT %0d",
                uut.registers[3]
            );


        // -----------------------------------------------------
        // TEST MEMORY
        // -----------------------------------------------------

        if (uut.data_memory[1] == 8'd25)

            $display(
                "PASS: MEMORY[1] = 25"
            );

        else

            $display(
                "FAIL: EXPECTED MEMORY[1] = 25, GOT %0d",
                uut.data_memory[1]
            );


        // -----------------------------------------------------
        // TEST OUTPUT
        // -----------------------------------------------------

        if (output_data == 8'd12)

            $display(
                "PASS: OUTPUT = 12"
            );

        else

            $display(
                "FAIL: EXPECTED OUTPUT = 12, GOT %0d",
                output_data
            );


        // -----------------------------------------------------
        // TEST HALT
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
            uut.registers[0] == 8'd12 &&
            uut.registers[1] == 8'd5 &&
            uut.registers[2] == 8'd25 &&
            uut.registers[3] == 8'd25 &&
            uut.data_memory[1] == 8'd25 &&
            output_data == 8'd12 &&
            halted == 1'b1
        ) begin

            $display("");
            $display("==============================================");
            $display("ALL 8-BIT SINGLE-CYCLE CPU TESTS PASSED");
            $display("==============================================");

        end

        else begin

            $display("");
            $display("==============================================");
            $display("8-BIT SINGLE-CYCLE CPU TEST FAILED");
            $display("==============================================");

        end


        #10;

        $finish;

    end

endmodule