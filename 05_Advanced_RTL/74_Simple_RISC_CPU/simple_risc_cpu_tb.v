`timescale 1ns/1ps

module simple_risc_cpu_tb;

    reg clk;
    reg rst;

    wire [7:0] output_data;
    wire [4:0] pc;
    wire halted;


    // =========================================================
    // DUT
    // =========================================================

    simple_risc_cpu uut (

        .clk(clk),
        .rst(rst),

        .output_data(output_data),
        .pc(pc),
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

        $dumpfile("simple_risc_cpu.vcd");

        $dumpvars(0, simple_risc_cpu_tb);

    end


    // =========================================================
    // MONITOR
    // =========================================================

    always @(posedge clk) begin

        #1;

        $display(
            "TIME=%0t | PC=%0d | INSTR=%b | R0=%0d | R1=%0d | R2=%0d | R3=%0d | R4=%0d | MEM1=%0d | OUT=%0d | HALT=%b",
            $time,
            pc,
            uut.instruction,
            uut.registers[0],
            uut.registers[1],
            uut.registers[2],
            uut.registers[3],
            uut.registers[4],
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
        // WAIT FOR HALT
        // -----------------------------------------------------

        wait (halted == 1'b1);

        #10;


        // -----------------------------------------------------
        // R1
        // -----------------------------------------------------

        if (uut.registers[1] == 8'd13)

            $display("PASS: R1 = 13");

        else

            $display(
                "FAIL: EXPECTED R1 = 13, GOT %0d",
                uut.registers[1]
            );


        // -----------------------------------------------------
        // R2
        // -----------------------------------------------------

        if (uut.registers[2] == 8'd5)

            $display("PASS: R2 = 5");

        else

            $display(
                "FAIL: EXPECTED R2 = 5, GOT %0d",
                uut.registers[2]
            );


        // -----------------------------------------------------
        // R3
        // -----------------------------------------------------

        if (uut.registers[3] == 8'd20)

            $display("PASS: R3 = 20");

        else

            $display(
                "FAIL: EXPECTED R3 = 20, GOT %0d",
                uut.registers[3]
            );


        // -----------------------------------------------------
        // R4
        // -----------------------------------------------------

        if (uut.registers[4] == 8'd20)

            $display("PASS: R4 = 20");

        else

            $display(
                "FAIL: EXPECTED R4 = 20, GOT %0d",
                uut.registers[4]
            );


        // -----------------------------------------------------
        // MEMORY
        // -----------------------------------------------------

        if (uut.data_memory[1] == 8'd20)

            $display("PASS: MEMORY[1] = 20");

        else

            $display(
                "FAIL: EXPECTED MEMORY[1] = 20, GOT %0d",
                uut.data_memory[1]
            );


        // -----------------------------------------------------
        // OUTPUT
        // -----------------------------------------------------

        if (output_data == 8'd13)

            $display("PASS: OUTPUT = 13");

        else

            $display(
                "FAIL: EXPECTED OUTPUT = 13, GOT %0d",
                output_data
            );


        // -----------------------------------------------------
        // HALT
        // -----------------------------------------------------

        if (halted == 1'b1)

            $display("PASS: CPU HALTED");

        else

            $display("FAIL: CPU DID NOT HALT");


        // -----------------------------------------------------
        // FINAL RESULT
        // -----------------------------------------------------

        if (
            uut.registers[1] == 8'd13 &&
            uut.registers[2] == 8'd5 &&
            uut.registers[3] == 8'd20 &&
            uut.registers[4] == 8'd20 &&
            uut.data_memory[1] == 8'd20 &&
            output_data == 8'd13 &&
            halted == 1'b1
        ) begin

            $display("");
            $display("==============================================");
            $display("ALL SIMPLE RISC CPU TESTS PASSED");
            $display("==============================================");

        end

        else begin

            $display("");
            $display("==============================================");
            $display("SIMPLE RISC CPU TEST FAILED");
            $display("==============================================");

        end


        #10;

        $finish;

    end

endmodule