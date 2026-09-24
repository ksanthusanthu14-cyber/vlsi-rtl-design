`timescale 1ns/1ps

module alu_self_check_tb;

    localparam int WIDTH = 8;

    logic [WIDTH-1:0] A;
    logic [WIDTH-1:0] B;
    logic [3:0]       opcode;

    logic [WIDTH-1:0] result;
    logic             carry;
    logic             zero;
    logic             overflow;


    //==================================================
    // REFERENCE MODEL OUTPUTS
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

    task automatic calculate_expected;

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
                    expected_carry  = (A != 0);

                end


                //======================================
                // INVALID OPCODE
                //======================================

                default: begin

                    expected_result   = '0;
                    expected_carry    = 1'b0;
                    expected_overflow = 1'b0;

                end

            endcase


            // ZERO FLAG

            if (expected_result == '0)
                expected_zero = 1'b1;
            else
                expected_zero = 1'b0;

        end

    endtask


    //==================================================
    // CHECK TASK
    //==================================================

    task automatic check_alu;

        begin

            #1;

            calculate_expected();

            total_tests = total_tests + 1;


            if ((result === expected_result) &&
                (carry === expected_carry) &&
                (zero === expected_zero) &&
                (overflow === expected_overflow)) begin

                passed_tests = passed_tests + 1;

                $display(
                    "PASS: TEST=%0d OP=%b A=%h B=%h RESULT=%h C=%b Z=%b V=%b",
                    total_tests,
                    opcode,
                    A,
                    B,
                    result,
                    carry,
                    zero,
                    overflow
                );

            end

            else begin

                failed_tests = failed_tests + 1;

                $display(
                    "FAIL: TEST=%0d OP=%b A=%h B=%h",
                    total_tests,
                    opcode,
                    A,
                    B
                );

                $display(
                    "      DUT      : RESULT=%h C=%b Z=%b V=%b",
                    result,
                    carry,
                    zero,
                    overflow
                );

                $display(
                    "      EXPECTED : RESULT=%h C=%b Z=%b V=%b",
                    expected_result,
                    expected_carry,
                    expected_zero,
                    expected_overflow
                );

            end

        end

    endtask


    //==================================================
    // TEST
    //==================================================

    initial begin

        $dumpfile("alu_self_check.vcd");
        $dumpvars(0, alu_self_check_tb);


        total_tests  = 0;
        passed_tests = 0;
        failed_tests = 0;

        A      = '0;
        B      = '0;
        opcode = '0;


        $display("");
        $display("==============================================");
        $display("SELF-CHECKING SYSTEMVERILOG ALU");
        $display("==============================================");


        //================================================
        // ADD TESTS
        //================================================

        A = 8'h0A;
        B = 8'h05;
        opcode = 4'b0000;
        check_alu();


        A = 8'hFF;
        B = 8'h01;
        opcode = 4'b0000;
        check_alu();


        A = 8'h7F;
        B = 8'h01;
        opcode = 4'b0000;
        check_alu();


        A = 8'h80;
        B = 8'h80;
        opcode = 4'b0000;
        check_alu();


        //================================================
        // SUB TESTS
        //================================================

        A = 8'h0A;
        B = 8'h05;
        opcode = 4'b0001;
        check_alu();


        A = 8'h05;
        B = 8'h0A;
        opcode = 4'b0001;
        check_alu();


        A = 8'h80;
        B = 8'h01;
        opcode = 4'b0001;
        check_alu();


        A = 8'h7F;
        B = 8'hFF;
        opcode = 4'b0001;
        check_alu();


        //================================================
        // LOGIC OPERATIONS
        //================================================

        A = 8'hAA;
        B = 8'h0F;
        opcode = 4'b0010;
        check_alu();


        A = 8'hA0;
        B = 8'h0F;
        opcode = 4'b0011;
        check_alu();


        A = 8'hAA;
        B = 8'hFF;
        opcode = 4'b0100;
        check_alu();


        A = 8'hAA;
        B = 8'h00;
        opcode = 4'b0101;
        check_alu();


        //================================================
        // SHIFT OPERATIONS
        //================================================

        A = 8'b10000001;
        B = 8'h00;
        opcode = 4'b0110;
        check_alu();


        A = 8'b00000011;
        B = 8'h00;
        opcode = 4'b0111;
        check_alu();


        A = 8'h00;
        B = 8'h00;
        opcode = 4'b0110;
        check_alu();


        A = 8'h01;
        B = 8'h00;
        opcode = 4'b0111;
        check_alu();


        //================================================
        // INCREMENT
        //================================================

        A = 8'h0F;
        B = 8'h00;
        opcode = 4'b1000;
        check_alu();


        A = 8'hFF;
        B = 8'h00;
        opcode = 4'b1000;
        check_alu();


        //================================================
        // DECREMENT
        //================================================

        A = 8'h10;
        B = 8'h00;
        opcode = 4'b1001;
        check_alu();


        A = 8'h00;
        B = 8'h00;
        opcode = 4'b1001;
        check_alu();


        //================================================
        // ZERO RESULT TESTS
        //================================================

        A = 8'h00;
        B = 8'h00;
        opcode = 4'b0000;
        check_alu();


        A = 8'h55;
        B = 8'h55;
        opcode = 4'b0001;
        check_alu();


        A = 8'h00;
        B = 8'h00;
        opcode = 4'b0010;
        check_alu();


        A = 8'h00;
        B = 8'h00;
        opcode = 4'b0100;
        check_alu();


        //================================================
        // SUMMARY
        //================================================

        $display("");
        $display("==============================================");
        $display("SELF-CHECKING ALU SUMMARY");
        $display("==============================================");

        $display("TOTAL TESTS  = %0d", total_tests);
        $display("PASSED TESTS = %0d", passed_tests);
        $display("FAILED TESTS = %0d", failed_tests);


        if (failed_tests == 0)

            $display("OVERALL RESULT = PASS");

        else

            $display("OVERALL RESULT = FAIL");


        $display("==============================================");
        $display("SELF-CHECKING ALU VERIFICATION COMPLETE");
        $display("==============================================");


        $finish;

    end

endmodule