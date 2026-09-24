class fifo_agent;

    fifo_sequencer sequencer;
    fifo_driver    driver;
    fifo_monitor   monitor;

    function new;
    begin

        sequencer = new;
        driver    = new;
        monitor   = new;

    end
    endfunction

endclass