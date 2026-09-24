class fifo_test;

    fifo_env env;

    function new;
    begin

        env = new;

    end
    endfunction


    task get_transaction;

        output fifo_transaction tr;

        begin

            tr = new;

            tr.randomize_transaction;

        end

    endtask

endclass