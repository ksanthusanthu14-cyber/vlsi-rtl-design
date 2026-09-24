`include "uart_transaction.sv"

class uart_driver;

    task drive(
        input [7:0] data,
        output reg tx_start,
        output reg [7:0] tx_data
    );

        tx_data  = data;
        tx_start = 1'b1;

        #1;

        tx_start = 1'b0;

        $display(
            "[DRIVER] Transmitting DATA = %02h",
            data
        );

    endtask

endclass