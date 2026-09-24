class alu_transaction;

    reg [7:0] a;
    reg [7:0] b;
    reg [2:0] op;
    reg [7:0] result;

    function new;
    begin
        a = 0;
        b = 0;
        op = 0;
        result = 0;
    end
    endfunction

    task randomize_transaction;
    begin

        a  = $random;
        b  = $random;

        op = $random % 6;

        if (op < 0)
            op = -op;

    end
    endtask

endclass