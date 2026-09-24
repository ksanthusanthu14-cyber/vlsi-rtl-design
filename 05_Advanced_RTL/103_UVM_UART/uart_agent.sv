class uart_agent;

    uart_sequencer sequencer;
    uart_driver    driver;
    uart_monitor   monitor;

    function new();

        sequencer = new();
        driver    = new();
        monitor   = new();

    endfunction

    task start;

        $display("[AGENT] UART agent started");

    endtask

endclass