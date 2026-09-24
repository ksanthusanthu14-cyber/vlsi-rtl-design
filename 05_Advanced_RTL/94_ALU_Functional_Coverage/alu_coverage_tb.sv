`timescale 1ns/1ps

module alu_coverage_tb;

    localparam WIDTH = 8;

    //============================================================
    // DUT SIGNALS
    //============================================================

    logic [WIDTH-1:0] a;
    logic [WIDTH-1:0] b;
    logic [3:0]       op;

    logic [WIDTH-1:0] result;
    logic             carry;
    logic             zero;
    logic             overflow;


    //============================================================
    // DUT
    //============================================================

    alu #(
        .WIDTH(WIDTH)
    ) dut (
        .a(a),
        .b(b),
        .op(op),
        .result(result),
        .carry(carry),
        .zero(zero),
        .overflow(overflow)
    );


    //============================================================
    // COVERAGE COUNTERS
    //============================================================

    integer total_tests;

    integer operation_hits [0:9];

    integer zero_result_hits;
    integer carry_hits;
    integer overflow_hits;
    integer boundary_hits;
    integer random_hits;

    integer cross_coverage [0:9][0:2];


    //============================================================
    // COVERAGE SUMMARY VARIABLES
    //============================================================

    integer operation_bins_hit;
    integer cross_bins_hit;

    integer total_operation_bins;
    integer total_cross_bins;

    integer coverage_percent;


    //============================================================
    // REFERENCE MODEL
    //============================================================

    reg [WIDTH-1:0] expected_result;


    //============================================================
    // INPUT CLASS
    //
    // 0 = ZERO
    // 1 = NORMAL
    // 2 = MAX
    //============================================================

    integer input_class;


    //============================================================
    // COVERAGE UPDATE
    //============================================================

    task automatic update_coverage;

        begin

            total_tests = total_tests + 1;


            //====================================================
            // OPERATION COVERAGE
            //====================================================

            operation_hits[op] =
                operation_hits[op] + 1;


            //====================================================
            // RESULT COVERAGE
            //====================================================

            if (zero)
                zero_result_hits =
                    zero_result_hits + 1;


            if (carry)
                carry_hits =
                    carry_hits + 1;


            if (overflow)
                overflow_hits =
                    overflow_hits + 1;


            //====================================================
            // INPUT CLASSIFICATION
            //====================================================

            if ((a == 8'h00) &&
                (b == 8'h00))

                input_class = 0;

            else if ((a == 8'hFF) &&
                     (b == 8'hFF))

                input_class = 2;

            else

                input_class = 1;


            //====================================================
            // CROSS COVERAGE
            //====================================================

            cross_coverage[op][input_class] =
                cross_coverage[op][input_class] + 1;


            //====================================================
            // BOUNDARY COVERAGE
            //====================================================

            if ((a == 8'h00) ||
                (a == 8'h01) ||
                (a == 8'h7F) ||
                (a == 8'h80) ||
                (a == 8'hFE) ||
                (a == 8'hFF) ||

                (b == 8'h00) ||
                (b == 8'h01) ||
                (b == 8'h7F) ||
                (b == 8'h80) ||
                (b == 8'hFE) ||
                (b == 8'hFF))

                boundary_hits =
                    boundary_hits + 1;

        end

    endtask


    //============================================================
    // ALU CHECK TASK
    //============================================================

    task automatic check_operation;

        input [7:0] ta;
        input [7:0] tb;
        input [3:0] top;

        begin

            a  = ta;
            b  = tb;
            op = top;

            #1;


            //====================================================
            // REFERENCE MODEL
            //====================================================

            expected_result = 8'h00;


            case (top)

                // ADD
                4'b0000:
                    expected_result = ta + tb;


                // SUB
                4'b0001:
                    expected_result = ta - tb;


                // AND
                4'b0010:
                    expected_result = ta & tb;


                // OR
                4'b0011:
                    expected_result = ta | tb;


                // XOR
                4'b0100:
                    expected_result = ta ^ tb;


                // NOT
                4'b0101:
                    expected_result = ~ta;


                // SHIFT LEFT
                4'b0110:
                    expected_result = ta << 1;


                // SHIFT RIGHT
                4'b0111:
                    expected_result = ta >> 1;


                // INCREMENT
                4'b1000:
                    expected_result = ta + 1'b1;


                // DECREMENT
                4'b1001:
                    expected_result = ta - 1'b1;


                default:
                    expected_result = 8'h00;

            endcase


            //====================================================
            // RESULT CHECK
            //====================================================

            if (result === expected_result) begin

                $display(
                    "PASS: OP=%0d A=%02h B=%02h RESULT=%02h",
                    top,
                    ta,
                    tb,
                    result
                );

            end

            else begin

                $display(
                    "FAIL: OP=%0d A=%02h B=%02h RESULT=%02h EXPECTED=%02h",
                    top,
                    ta,
                    tb,
                    result,
                    expected_result
                );

            end


            update_coverage;

        end

    endtask


    //============================================================
    // INITIALIZATION
    //============================================================

    integer i;


    initial begin

        $dumpfile("alu_coverage.vcd");
        $dumpvars(0, alu_coverage_tb);


        total_tests      = 0;

        zero_result_hits = 0;
        carry_hits       = 0;
        overflow_hits    = 0;
        boundary_hits    = 0;
        random_hits      = 0;


        operation_bins_hit = 0;
        cross_bins_hit     = 0;

        total_operation_bins = 10;
        total_cross_bins     = 30;

        coverage_percent = 0;


        //========================================================
        // CLEAR OPERATION COVERAGE
        //========================================================

        for (i = 0; i < 10; i = i + 1)

            operation_hits[i] = 0;


        //========================================================
        // CLEAR CROSS COVERAGE
        //========================================================

        for (i = 0; i < 10; i = i + 1) begin

            cross_coverage[i][0] = 0;
            cross_coverage[i][1] = 0;
            cross_coverage[i][2] = 0;

        end


        //========================================================
        // TEST 1
        // DIRECTED FUNCTIONAL COVERAGE
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 1: DIRECTED FUNCTIONAL COVERAGE");
        $display("==============================================");


        // ADD
        check_operation(8'h05, 8'h03, 4'b0000);
        check_operation(8'hFF, 8'h01, 4'b0000);
        check_operation(8'h7F, 8'h01, 4'b0000);


        // SUB
        check_operation(8'h08, 8'h03, 4'b0001);
        check_operation(8'h00, 8'h01, 4'b0001);
        check_operation(8'h80, 8'h01, 4'b0001);


        // AND
        check_operation(8'hAA, 8'h55, 4'b0010);


        // OR
        check_operation(8'hAA, 8'h55, 4'b0011);


        // XOR
        check_operation(8'hAA, 8'h55, 4'b0100);


        // NOT
        check_operation(8'h00, 8'h00, 4'b0101);


        // SHIFT LEFT
        check_operation(8'h81, 8'h00, 4'b0110);


        // SHIFT RIGHT
        check_operation(8'h81, 8'h00, 4'b0111);


        // INCREMENT
        check_operation(8'hFF, 8'h00, 4'b1000);


        // DECREMENT
        check_operation(8'h00, 8'h00, 4'b1001);


        // ZERO RESULT CASES
        check_operation(8'h00, 8'h00, 4'b0000);
        check_operation(8'h55, 8'h55, 4'b0001);
        check_operation(8'h00, 8'h00, 4'b0010);
        check_operation(8'h00, 8'h00, 4'b0100);


        //========================================================
        // TEST 2
        // RANDOMIZED FUNCTIONAL COVERAGE
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 2: RANDOMIZED FUNCTIONAL COVERAGE");
        $display("==============================================");


        for (i = 0; i < 300; i = i + 1) begin

            a  = $random;
            b  = $random;
            op = $random % 10;

            #1;

            random_hits = random_hits + 1;

            update_coverage;

        end


        //========================================================
        // TEST 3
        // COVERAGE BIN COMPLETION
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 3: COVERAGE BIN COMPLETION");
        $display("==============================================");


        for (i = 0; i < 10; i = i + 1) begin

            // ZERO INPUT CLASS
            check_operation(
                8'h00,
                8'h00,
                i[3:0]
            );


            // NORMAL INPUT CLASS
            check_operation(
                8'h12,
                8'h34,
                i[3:0]
            );


            // MAX INPUT CLASS
            check_operation(
                8'hFF,
                8'hFF,
                i[3:0]
            );

        end


        //========================================================
        // CALCULATE OPERATION BIN COVERAGE
        //========================================================

        operation_bins_hit = 0;

        for (i = 0; i < 10; i = i + 1) begin

            if (operation_hits[i] > 0)

                operation_bins_hit =
                    operation_bins_hit + 1;

        end


        //========================================================
        // CALCULATE CROSS COVERAGE
        //========================================================

        cross_bins_hit = 0;

        for (i = 0; i < 10; i = i + 1) begin

            if (cross_coverage[i][0] > 0)

                cross_bins_hit =
                    cross_bins_hit + 1;


            if (cross_coverage[i][1] > 0)

                cross_bins_hit =
                    cross_bins_hit + 1;


            if (cross_coverage[i][2] > 0)

                cross_bins_hit =
                    cross_bins_hit + 1;

        end


        //========================================================
        // CALCULATE OVERALL COVERAGE
        //========================================================

        coverage_percent =
            ((operation_bins_hit + cross_bins_hit) * 100) /
            (total_operation_bins + total_cross_bins);


        //========================================================
        // COVERAGE REPORT
        //========================================================

        $display("");
        $display("==============================================");
        $display("ALU FUNCTIONAL COVERAGE REPORT");
        $display("==============================================");


        $display(
            "TOTAL TESTS = %0d",
            total_tests
        );


        $display("");
        $display("OPERATION COVERAGE");
        $display("----------------------------------------------");


        for (i = 0; i < 10; i = i + 1) begin

            $display(
                "OP %0d : %0d hits",
                i,
                operation_hits[i]
            );

        end


        $display("");
        $display(
            "ZERO RESULT COVERAGE = %0d",
            zero_result_hits
        );


        $display(
            "CARRY COVERAGE       = %0d",
            carry_hits
        );


        $display(
            "OVERFLOW COVERAGE    = %0d",
            overflow_hits
        );


        $display(
            "BOUNDARY COVERAGE    = %0d",
            boundary_hits
        );


        //========================================================
        // CROSS COVERAGE
        //========================================================

        $display("");
        $display("CROSS COVERAGE");
        $display("----------------------------------------------");
        $display("Operation       ZERO       NORMAL       MAX");
        $display("----------------------------------------------");


        for (i = 0; i < 10; i = i + 1) begin

            $display(
                "OP %0d            %0d          %0d          %0d",
                i,
                cross_coverage[i][0],
                cross_coverage[i][1],
                cross_coverage[i][2]
            );

        end


        //========================================================
        // FINAL COVERAGE SUMMARY
        //========================================================

        $display("");
        $display("==============================================");
        $display("COVERAGE SUMMARY");
        $display("==============================================");


        $display(
            "OPERATION BINS HIT = %0d / %0d",
            operation_bins_hit,
            total_operation_bins
        );


        $display(
            "CROSS BINS HIT     = %0d / %0d",
            cross_bins_hit,
            total_cross_bins
        );


        $display(
            "FUNCTIONAL COVERAGE = %0d%%",
            coverage_percent
        );


        $display("==============================================");


        if ((operation_bins_hit == total_operation_bins) &&
            (cross_bins_hit == total_cross_bins)) begin

            $display(
                "OVERALL COVERAGE RESULT = 100%%"
            );

        end

        else begin

            $display(
                "OVERALL COVERAGE RESULT = INCOMPLETE"
            );

        end


        $display("==============================================");


        $display(
            "ALU FUNCTIONAL COVERAGE VERIFICATION COMPLETE"
        );


        $finish;

    end

endmodule