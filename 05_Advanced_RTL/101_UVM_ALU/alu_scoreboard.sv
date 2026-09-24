class alu_scoreboard;

    integer total;
    integer passed;
    integer failed;

    function new;
    begin
        total  = 0;
        passed = 0;
        failed = 0;
    end
    endfunction


    function [7:0] calculate_expected;

        input [7:0] a;
        input [7:0] b;
        input [2:0] op;

        begin

            case (op)

                3'b000:
                    calculate_expected = a + b;

                3'b001:
                    calculate_expected = a - b;

                3'b010:
                    calculate_expected = a & b;

                3'b011:
                    calculate_expected = a | b;

                3'b100:
                    calculate_expected = a ^ b;

                3'b101:
                    calculate_expected = ~a;

                default:
                    calculate_expected = 8'h00;

            endcase

        end

    endfunction


    task check;

        input [7:0] a;
        input [7:0] b;
        input [2:0] op;
        input [7:0] result;

        reg [7:0] expected;

        begin

            expected = calculate_expected(a, b, op);

            total = total + 1;

            if (result === expected) begin

                passed = passed + 1;

                $display(
                    "PASS | A=%02h B=%02h OP=%03b RESULT=%02h EXPECTED=%02h",
                    a, b, op, result, expected
                );

            end
            else begin

                failed = failed + 1;

                $display(
                    "FAIL | A=%02h B=%02h OP=%03b RESULT=%02h EXPECTED=%02h",
                    a, b, op, result, expected
                );

            end

        end

    endtask


    task report;
    begin

        $display("");
        $display("======================================");
        $display("UVM-STYLE ALU SCOREBOARD SUMMARY");
        $display("======================================");

        $display("TOTAL CHECKS = %0d", total);
        $display("PASSED       = %0d", passed);
        $display("FAILED       = %0d", failed);

        if (failed == 0)
            $display("OVERALL RESULT = PASS");
        else
            $display("OVERALL RESULT = FAIL");

        $display("======================================");

    end
    endtask

endclass