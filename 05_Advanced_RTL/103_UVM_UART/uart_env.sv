class uart_env;

    uart_agent      agent;
    uart_scoreboard scoreboard;

    function new();

        agent      = new();
        scoreboard = new();

    endfunction

    task build;

        $display("[ENV] UART environment built");

    endtask

endclass