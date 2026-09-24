class alu_sequencer;

    function new;
    begin
    end
    endfunction

    task get_next_transaction;

        output alu_transaction tr;

        begin

            tr = new;

            tr.randomize_transaction;

        end

    endtask

endclass