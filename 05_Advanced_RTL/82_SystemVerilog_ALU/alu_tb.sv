`timescale 1ns/1ps

module alu_tb;

    localparam int WIDTH = 8;

    logic [WIDTH-1:0] A;
    logic [WIDTH-1:0] B;
    logic [3:0]       opcode;

    logic [WIDTH-1:0] result;
    logic             carry;
    logic             zero;
    logic             overflow;


    //==============================================
    // DUT
    //==============================================

    alu #(
        .WIDTH(WIDTH)
    ) dut (
        .A(A),
        .B(B),
        .opcode(opcode),
        .result(result),
        .carry(carry),
        .zero(zero),
        .overflow(overflow)
    );


    //==============================================
    // TEST TASK
    //==============================================

    task automatic test_alu(
        input logic [WIDTH-1:0] test_A,
        input logic [WIDTH-1:0] test_B,
        input logic [3:0] test_opcode,
        input logic [WIDTH-1:0] expected_result,
        input logic expected_carry,
        input logic expected_zero,
        input logic expected_overflow,
        input string operation
    );

        begin

            A      = test_A;
            B      = test_B;
            opcode = test_opcode;

            #1;

            if ((result === expected_result) &&
                (carry === expected_carry) &&
                (zero === expected_zero) &&
                (overflow === expected_overflow)) begin

                $display(
                    "PASS: %-12s A=%h B=%h RESULT=%h C=%b Z=%b V=%b",
                    operation,
                    A,
                    B,
                    result,
                    carry,
                    zero,
                    overflow
                );

            end
            else begin

                $display(
                    "FAIL: %-12s A=%h B=%h RESULT=%h C=%b Z=%b V=%b | EXPECTED RESULT=%h C=%b Z=%b V=%b",
                    operation,
                    A,
                    B,
                    result,
                    carry,
                    zero,
                    overflow,
                    expected_result,
                    expected_carry,
                    expected_zero,
                    expected_overflow
                );

            end

        end

    endtask


    //==============================================
    // TEST SEQUENCE
    //==============================================

    initial begin

        $dumpfile("alu.vcd");
        $dumpvars(0, alu_tb);


        $display("");
        $display("==============================================");
        $display("SYSTEMVERILOG ALU VERIFICATION");
        $display("==============================================");


        //==========================================
        // ADD
        //==========================================

        test_alu(
            8'h0A, 8'h05,
            4'b0000,
            8'h0F, 1'b0, 1'b0, 1'b0,
            "ADD"
        );


        // ADD with carry
        test_alu(
            8'hFF, 8'h01,
            4'b0000,
            8'h00, 1'b1, 1'b1, 1'b0,
            "ADD_CARRY"
        );


        //==========================================
        // SUB
        //==========================================

        test_alu(
            8'h0A, 8'h05,
            4'b0001,
            8'h05, 1'b1, 1'b0, 1'b0,
            "SUB"
        );


        //==========================================
        // AND
        //==========================================

        test_alu(
            8'hAA, 8'h0F,
            4'b0010,
            8'h0A, 1'b0, 1'b0, 1'b0,
            "AND"
        );


        //==========================================
        // OR
        //==========================================

        test_alu(
            8'hA0, 8'h0F,
            4'b0011,
            8'hAF, 1'b0, 1'b0, 1'b0,
            "OR"
        );


        //==========================================
        // XOR
        //==========================================

        test_alu(
            8'hAA, 8'hFF,
            4'b0100,
            8'h55, 1'b0, 1'b0, 1'b0,
            "XOR"
        );


        //==========================================
        // NOT
        //==========================================

        test_alu(
            8'hAA, 8'h00,
            4'b0101,
            8'h55, 1'b0, 1'b0, 1'b0,
            "NOT"
        );


        //==========================================
        // SHIFT LEFT
        //==========================================

        test_alu(
            8'b10000001, 8'h00,
            4'b0110,
            8'b00000010, 1'b1, 1'b0, 1'b0,
            "SHIFT_LEFT"
        );


        //==========================================
        // SHIFT RIGHT
        //==========================================

        test_alu(
            8'b00000011, 8'h00,
            4'b0111,
            8'b00000001, 1'b1, 1'b0, 1'b0,
            "SHIFT_RIGHT"
        );


        //==========================================
        // INCREMENT
        //==========================================

        test_alu(
            8'h0F, 8'h00,
            4'b1000,
            8'h10, 1'b0, 1'b0, 1'b0,
            "INCREMENT"
        );


        //==========================================
        // DECREMENT
        //==========================================

        test_alu(
            8'h10, 8'h00,
            4'b1001,
            8'h0F, 1'b1, 1'b0, 1'b0,
            "DECREMENT"
        );


        //==========================================
        // ZERO RESULT
        //==========================================

        test_alu(
            8'h00, 8'h00,
            4'b0000,
            8'h00, 1'b0, 1'b1, 1'b0,
            "ZERO_RESULT"
        );


        //==========================================
        // SIGNED OVERFLOW
        // 127 + 1 = -128 in 8-bit signed arithmetic
        //==========================================

        test_alu(
            8'h7F, 8'h01,
            4'b0000,
            8'h80, 1'b0, 1'b0, 1'b1,
            "ADD_OVERFLOW"
        );


        //==========================================
        // SIGNED OVERFLOW
        // -128 - 1 = 127
        //==========================================

        test_alu(
            8'h80, 8'h01,
            4'b0001,
            8'h7F, 1'b1, 1'b0, 1'b1,
            "SUB_OVERFLOW"
        );


        $display("");
        $display("==============================================");
        $display("SYSTEMVERILOG ALU VERIFICATION COMPLETE");
        $display("==============================================");

        $finish;

    end

endmodule