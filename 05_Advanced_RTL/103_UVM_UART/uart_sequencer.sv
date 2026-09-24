`include "uart_transaction.sv"

class uart_sequencer;

    uart_transaction tr;

    function new();
        tr = new();
    endfunction

    task generate_transaction(input [7:0] value);

        tr = new();
        tr.data = value;

    endtask

endclass