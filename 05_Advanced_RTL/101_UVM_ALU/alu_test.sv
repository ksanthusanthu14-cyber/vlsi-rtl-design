class alu_test;

    alu_env env;

    function new;
    begin
        env = new;
    end
    endfunction


    task get_transaction;

        output alu_transaction tr;

        begin

            tr = new;

            tr.randomize_transaction;

        end

    endtask

endclass