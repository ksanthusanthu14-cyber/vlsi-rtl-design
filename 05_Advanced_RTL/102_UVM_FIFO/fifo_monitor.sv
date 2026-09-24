class fifo_monitor;

    function new;
    begin
    end
    endfunction


    task sample;

        input write_en;
        input read_en;
        input [7:0] write_data;

        input [7:0] read_data;

        input full;
        input empty;

        begin

            $display(
                "MONITOR | WRITE=%0d READ=%0d WDATA=%02h RDATA=%02h FULL=%0d EMPTY=%0d",
                write_en,
                read_en,
                write_data,
                read_data,
                full,
                empty
            );

        end

    endtask

endclass