class fifo_transaction;

    reg        write_en;
    reg        read_en;
    reg [7:0]  write_data;

    reg [7:0]  read_data;

    reg        full;
    reg        empty;

    function new;
    begin

        write_en  = 0;
        read_en   = 0;
        write_data = 0;

        read_data = 0;

        full  = 0;
        empty = 1;

    end
    endfunction


    task randomize_transaction;

        integer r;

        begin

            r = $random;

            if (r < 0)
                r = -r;

            case (r % 4)

                0: begin
                    write_en = 1;
                    read_en  = 0;
                end

                1: begin
                    write_en = 0;
                    read_en  = 1;
                end

                2: begin
                    write_en = 1;
                    read_en  = 1;
                end

                3: begin
                    write_en = 0;
                    read_en  = 0;
                end

            endcase


            write_data = $random;

        end

    endtask

endclass