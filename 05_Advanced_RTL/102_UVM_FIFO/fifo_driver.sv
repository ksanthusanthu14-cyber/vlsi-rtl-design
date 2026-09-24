class fifo_driver;

    function new;
    begin
    end
    endfunction


    task drive;

        input write_en;
        input read_en;
        input [7:0] write_data;

        begin

            $display(
                "DRIVER  | WRITE=%0d READ=%0d DATA=%02h",
                write_en,
                read_en,
                write_data
            );

        end

    endtask

endclass