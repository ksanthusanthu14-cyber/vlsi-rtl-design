class uart_transaction;

    reg [7:0] data;
    reg [7:0] expected;
    reg [7:0] received;

    reg tx_done;
    reg rx_valid;
    reg rx_error;

    task randomize_transaction;
        data = $random;
    endtask

    task display(string name);
        $display(
            "%s DATA=%02h EXPECTED=%02h RECEIVED=%02h TX_DONE=%b RX_VALID=%b RX_ERROR=%b",
            name,
            data,
            expected,
            received,
            tx_done,
            rx_valid,
            rx_error
        );
    endtask

endclass