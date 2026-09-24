`timescale 1ns/1ps

module randomized_alu_tb;

    localparam int WIDTH = 8;

    // Number of randomized transactions
    localparam int RANDOM_TESTS = 500;


    //==================================================
    // DUT SIGNALS
    //==================================================

    logic [WIDTH-1:0] A;
    logic [WIDTH-1:0] B;
    logic [3:0]       opcode;

    logic [WIDTH-1:0] result;
    logic             carry;
    logic             zero;
    logic             overflow;


    //==================================================
    // REFERENCE MODEL
    //==================================================

    logic [WIDTH-1:0] expected_result;
    logic             expected_carry;
    logic             expected_zero;
    logic             expected_overflow;

    logic [WIDTH:0] expected_temp;


    //==================================================
    // TEST COUNTERS
    //==================================================

    integer total_tests;
    integer passed_tests;
    integer failed_tests;


    //==================================================
    // OPCODE DISTRIBUTION
    //==================================================

    integer opcode_count [0:9];


    //==================================================
    // DUT
    //==================================================

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


    //==================================================
    // REFERENCE MODEL
    //==================================================

    task automatic reference_model;

        begin

            expected_result   = '0;
            expected_carry    = 1'b0;
            expected_overflow = 1'b0;
            expected_temp     = '0;


            case (opcode)

                //======================================
                // ADD
                //======================================

                4'b0000: begin

                    expected_temp =
                        {1'b0, A} + {1'b0, B};

                    expected_result =
                        expected_temp[WIDTH-1:0];

                    expected_carry =
                        expected_temp[WIDTH];

                    expected_overflow =
                        (~(A[WIDTH-1] ^ B[WIDTH-1])) &
                        (expected_result[WIDTH-1] ^
                         A[WIDTH-1]);

                end


                //======================================
                // SUB
                //======================================

                4'b0001: begin

                    expected_result = A - B;

                    expected_carry = (A >= B);

                    expected_overflow =
                        (A[WIDTH-1] ^ B[WIDTH-1]) &
                        (expected_result[WIDTH-1] ^
                         A[WIDTH-1]);

                end


                //======================================
                // AND
                //======================================

                4'b0010: begin

                    expected_result = A & B;

                end


                //======================================
                // OR
                //======================================

                4'b0011: begin

                    expected_result = A | B;

                end


                //======================================
                // XOR
                //======================================

                4'b0100: begin

                    expected_result = A ^ B;

                end


                //======================================
                // NOT
                //======================================

                4'b0101: begin

                    expected_result = ~A;

                end


                //======================================
                // SHIFT LEFT
                //======================================

                4'b0110: begin

                    expected_result = A << 1;
                    expected_carry  = A[WIDTH-1];

                end


                //======================================
                // SHIFT RIGHT
                //======================================

                4'b0111: begin

                    expected_result = A >> 1;
                    expected_carry  = A[0];

                end


                //======================================
                // INCREMENT
                //======================================

                4'b1000: begin

                    expected_temp =
                        {1'b0, A} + 1'b1;

                    expected_result =
                        expected_temp[WIDTH-1:0];

                    expected_carry =
                        expected_temp[WIDTH];

                end


                //======================================
                // DECREMENT
                //======================================

                4'b1001: begin

                    expected_result = A - 1'b1;

                    expected_carry = (A != 0);

                end


                //======================================
                // INVALID
                //======================================

                default: begin

                    expected_result   = '0;
                    expected_carry    = 1'b0;
                    expected_overflow = 1'b0;

                end

            endcase


            expected_zero = (expected_result == '0);

        end

    endtask


    //==================================================
    // CHECK TRANSACTION
    //==================================================

    task automatic check_transaction;

        begin

            #1;

            reference_model();

            total_tests = total_tests + 1;


            if ((result === expected_result) &&
                (carry === expected_carry) &&
                (zero === expected_zero) &&
                (overflow === expected_overflow)) begin

                passed_tests = passed_tests + 1;

            end

            else begin

                failed_tests = failed_tests + 1;

                $display("");
                $display("*************** FAILURE ***************");

                $display(
                    "TEST=%0d OP=%b A=%h B=%h",
                    total_tests,
                    opcode,
                    A,
                    B
                );

                $display(
                    "DUT      : RESULT=%h C=%b Z=%b V=%b",
                    result,
                    carry,
                    zero,
                    overflow
                );

                $display(
                    "EXPECTED : RESULT=%h C=%b Z=%b V=%b",
                    expected_result,
                    expected_carry,
                    expected_zero,
                    expected_overflow
                );

                $display("***************************************");
                $display("");

            end

        end

    endtask


    //==================================================
    // DIRECTED TEST
    //==================================================

    task automatic directed_test(
        input logic [WIDTH-1:0] test_A,
        input logic [WIDTH-1:0] test_B,
        input logic [3:0] test_opcode
    );

        begin

            A      = test_A;
            B      = test_B;
            opcode = test_opcode;

            check_transaction();

        end

    endtask


    //==================================================
    // RANDOM TRANSACTION
    //==================================================

    task automatic random_transaction;

        integer op;

        begin

            // Random 8-bit operands
            A = $urandom_range(0, 255);
            B = $urandom_range(0, 255);

            // Random valid opcode 0-9
            op = $urandom_range(0, 9);

            opcode = op;

            opcode_count[op] =
                opcode_count[op] + 1;

            check_transaction();

        end

    endtask


    //==================================================
    // MAIN TEST
    //==================================================

    initial begin : main_test

        integer i;


        //================================================
        // VCD
        //================================================

        $dumpfile("randomized_alu.vcd");
        $dumpvars(0, randomized_alu_tb);


        //================================================
        // INITIALIZE COUNTERS
        //================================================

        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;


        for (i = 0; i < 10; i = i + 1)

            opcode_count[i] = 0;


        A      = '0;
        B      = '0;
        opcode = '0;


        //================================================
        // HEADER
        //================================================

        $display("");
        $display("==============================================");
        $display("RANDOMIZED ALU VERIFICATION");
        $display("==============================================");

        $display(
            "RANDOM TRANSACTIONS = %0d",
            RANDOM_TESTS
        );


        //================================================
        // DIRECTED CORNER CASES
        //================================================

        $display("");
        $display("RUNNING DIRECTED CORNER CASES");


        // ADD: FF + 01
        directed_test(
            8'hFF,
            8'h01,
            4'b0000
        );


        // ADD signed overflow
        directed_test(
            8'h7F,
            8'h01,
            4'b0000
        );


        // ADD signed overflow negative
        directed_test(
            8'h80,
            8'h80,
            4'b0000
        );


        // SUB: 00 - 01
        directed_test(
            8'h00,
            8'h01,
            4'b0001
        );


        // SUB signed overflow
        directed_test(
            8'h80,
            8'h01,
            4'b0001
        );


        // AND
        directed_test(
            8'hFF,
            8'h00,
            4'b0010
        );


        // OR
        directed_test(
            8'h00,
            8'hFF,
            4'b0011
        );


        // XOR
        directed_test(
            8'hAA,
            8'h55,
            4'b0100
        );


        // NOT
        directed_test(
            8'h00,
            8'h00,
            4'b0101
        );


        // SHIFT LEFT
        directed_test(
            8'h80,
            8'h00,
            4'b0110
        );


        // SHIFT RIGHT
        directed_test(
            8'h01,
            8'h00,
            4'b0111
        );


        // INCREMENT
        directed_test(
            8'hFF,
            8'h00,
            4'b1000
        );


        // DECREMENT
        directed_test(
            8'h00,
            8'h00,
            4'b1001
        );


        //================================================
        // RANDOMIZED TESTS
        //================================================

        $display("");
        $display("RUNNING RANDOMIZED TESTS");


        for (i = 0; i < RANDOM_TESTS; i = i + 1) begin

            random_transaction();

        end


        //================================================
        // SUMMARY
        //================================================

        $display("");
        $display("==============================================");
        $display("RANDOMIZED ALU VERIFICATION SUMMARY");
        $display("==============================================");


        $display(
            "TOTAL TESTS  = %0d",
            total_tests
        );


        $display(
            "PASSED TESTS = %0d",
            passed_tests
        );


        $display(
            "FAILED TESTS = %0d",
            failed_tests
        );


        //================================================
        // OPCODE DISTRIBUTION
        //================================================

        $display("");
        $display("OPCODE DISTRIBUTION");
        $display("----------------------------------------------");


        $display(
            "ADD         (0000) = %0d",
            opcode_count[0]
        );


        $display(
            "SUB         (0001) = %0d",
            opcode_count[1]
        );


        $display(
            "AND         (0010) = %0d",
            opcode_count[2]
        );


        $display(
            "OR          (0011) = %0d",
            opcode_count[3]
        );


        $display(
            "XOR         (0100) = %0d",
            opcode_count[4]
        );


        $display(
            "NOT         (0101) = %0d",
            opcode_count[5]
        );


        $display(
            "SHIFT_LEFT  (0110) = %0d",
            opcode_count[6]
        );


        $display(
            "SHIFT_RIGHT (0111) = %0d",
            opcode_count[7]
        );


        $display(
            "INCREMENT   (1000) = %0d",
            opcode_count[8]
        );


        $display(
            "DECREMENT   (1001) = %0d",
            opcode_count[9]
        );


        //================================================
        // FINAL RESULT
        //================================================

        $display("");
        $display("==============================================");


        if (failed_tests == 0)

            $display(
                "OVERALL RESULT = PASS"
            );

        else

            $display(
                "OVERALL RESULT = FAIL"
            );


        $display("==============================================");


        $display("");
        $display(
            "RANDOMIZED ALU VERIFICATION COMPLETE"
        );


        $display("==============================================");


        $finish;

    end

endmodule