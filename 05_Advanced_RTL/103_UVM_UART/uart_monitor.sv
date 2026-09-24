class uart_monitor;

    task observe(
        input [7:0] rx_data,
        input        rx_valid,
        input        rx_error
    );

        if (rx_valid) begin

            $display(
                "[MONITOR] RX DATA = %02h ERROR = %b",
                rx_data,
                rx_error
            );

        end

    endtask

endclass