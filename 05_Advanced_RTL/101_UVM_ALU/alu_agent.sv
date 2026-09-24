class alu_agent;

    alu_sequencer sequencer;
    alu_driver    driver;
    alu_monitor   monitor;

    function new;
    begin

        sequencer = new;
        driver    = new;
        monitor   = new;

    end
    endfunction

endclass