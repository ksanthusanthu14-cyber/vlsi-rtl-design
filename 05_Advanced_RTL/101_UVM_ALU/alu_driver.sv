class alu_driver;

    function new;
    begin
    end
    endfunction

    task drive;

        input [7:0] a;
        input [7:0] b;
        input [2:0] op;

        begin

            $display(
                "DRIVER  | A=%02h B=%02h OP=%03b",
                a, b, op
            );

        end

    endtask

endclass