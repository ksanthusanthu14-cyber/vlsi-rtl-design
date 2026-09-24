class fifo_env;

    fifo_agent      agent;
    fifo_scoreboard scoreboard;

    function new;
    begin

        agent      = new;
        scoreboard = new;

    end
    endfunction

endclass