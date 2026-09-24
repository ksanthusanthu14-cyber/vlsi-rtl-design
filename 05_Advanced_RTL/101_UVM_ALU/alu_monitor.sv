class alu_monitor;

    function new;
    begin
    end
    endfunction

    task sample;

        input [7:0] a;
        input [7:0] b;
        input [2:0] op;
        input [7:0] result;

        begin

            $display(
                "MONITOR | A=%02h B=%02h OP=%03b RESULT=%02h",
                a, b, op, result
            );

        end

    endtask

endclass