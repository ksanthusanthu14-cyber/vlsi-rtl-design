`timescale 1ns/1ps

module parameterized_fifo_tb;

    localparam int DATA_WIDTH = 8;
    localparam int DEPTH      = 16;

    logic clk;
    logic rst;

    logic wr_en;
    logic rd_en;

    logic [DATA_WIDTH-1:0] data_in;
    logic [DATA_WIDTH-1:0] data_out;

    logic full;
    logic empty;

    logic [$clog2(DEPTH+1)-1:0] count;


    //==================================================
    // DUT
    //==================================================

    parameterized_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),

        .wr_en(wr_en),
        .rd_en(rd_en),

        .data_in(data_in),
        .data_out(data_out),

        .full(full),
        .empty(empty),

        .count(count)
    );


    //==================================================
    // CLOCK
    //==================================================

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end


    //==================================================
    // WRITE TASK
    //==================================================

    task automatic write_item(
        input logic [DATA_WIDTH-1:0] value
    );

        begin

            @(negedge clk);

            wr_en   = 1'b1;
            rd_en   = 1'b0;
            data_in = value;

            @(posedge clk);

            #1;

            wr_en = 1'b0;

        end

    endtask


    //==================================================
    // READ TASK
    //==================================================

    task automatic read_item(
        input logic [DATA_WIDTH-1:0] expected
    );

        begin

            @(negedge clk);

            wr_en = 1'b0;
            rd_en = 1'b1;

            @(posedge clk);

            #1;

            if (data_out === expected)

                $display(
                    "PASS: READ=%h EXPECTED=%h COUNT=%0d",
                    data_out,
                    expected,
                    count
                );

            else

                $display(
                    "FAIL: READ=%h EXPECTED=%h COUNT=%0d",
                    data_out,
                    expected,
                    count
                );

            rd_en = 1'b0;

        end

    endtask


    //==================================================
    // TEST SEQUENCE
    //==================================================

    initial begin

        $dumpfile("parameterized_fifo.vcd");
        $dumpvars(0, parameterized_fifo_tb);


        //================================================
        // INITIAL CONDITIONS
        //================================================

        rst     = 1'b1;
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        data_in = '0;


        #12;

        rst = 1'b0;


        $display("");
        $display("==============================================");
        $display("PARAMETERIZED SYSTEMVERILOG FIFO VERIFICATION");
        $display("==============================================");


        //================================================
        // TEST 1: RESET
        //================================================

        if (empty && !full && count == 0)

            $display("PASS: RESET -> EMPTY");

        else

            $display("FAIL: RESET STATUS");


        //================================================
        // TEST 2: PARAMETERIZED WRITES
        //================================================

        $display("");
        $display("TEST 2: WRITE 8 ITEMS");

        write_item(8'h11);
        write_item(8'h22);
        write_item(8'h33);
        write_item(8'h44);
        write_item(8'h55);
        write_item(8'h66);
        write_item(8'h77);
        write_item(8'h88);

        #1;

        if (count == 8)

            $display("PASS: COUNT = %0d", count);

        else

            $display("FAIL: COUNT = %0d", count);


        //================================================
        // TEST 3: FIFO ORDER
        //================================================

        $display("");
        $display("TEST 3: FIFO ORDER");

        read_item(8'h11);
        read_item(8'h22);
        read_item(8'h33);
        read_item(8'h44);


        //================================================
        // TEST 4: WRITE AFTER READ
        //================================================

        $display("");
        $display("TEST 4: WRITE AFTER READ");

        write_item(8'h99);
        write_item(8'hAA);
        write_item(8'hBB);
        write_item(8'hCC);


        //================================================
        // TEST 5: CIRCULAR FIFO ORDER
        //================================================

        $display("");
        $display("TEST 5: CIRCULAR FIFO ORDER");

        read_item(8'h55);
        read_item(8'h66);
        read_item(8'h77);
        read_item(8'h88);
        read_item(8'h99);
        read_item(8'hAA);
        read_item(8'hBB);
        read_item(8'hCC);


        //================================================
        // TEST 6: FILL TO DEPTH
        //================================================

        $display("");
        $display("TEST 6: FILL FIFO TO DEPTH");

        for (int i = 0; i < DEPTH; i++) begin

            write_item(i + 8'hA0);

        end

        #1;

        if (full && count == DEPTH)

            $display(
                "PASS: FIFO FULL -> COUNT=%0d",
                count
            );

        else

            $display(
                "FAIL: FIFO FULL -> COUNT=%0d",
                count
            );


        //================================================
        // TEST 7: OVERFLOW
        //================================================

        $display("");
        $display("TEST 7: OVERFLOW PROTECTION");

        @(negedge clk);

        wr_en   = 1'b1;
        rd_en   = 1'b0;
        data_in = 8'hFF;

        @(posedge clk);

        #1;

        wr_en = 1'b0;

        if (count == DEPTH)

            $display("PASS: OVERFLOW BLOCKED");

        else

            $display("FAIL: OVERFLOW NOT BLOCKED");


        //================================================
        // TEST 8: READ FROM FULL FIFO
        //================================================

        $display("");
        $display("TEST 8: READ FROM FULL FIFO");

        read_item(8'hA0);

        if (count == 15)

            $display("PASS: FULL FIFO -> READ ACCEPTED -> COUNT=15");

        else

            $display(
                "FAIL: FULL FIFO READ -> COUNT=%0d",
                count
            );


        //================================================
        // TEST 9: TRUE SIMULTANEOUS READ/WRITE
        //================================================

        $display("");
        $display("TEST 9: SIMULTANEOUS READ/WRITE");

        // FIFO currently contains:
        //
        // A1 A2 A3 ... AF
        //
        // COUNT = 15
        //
        // Read A1 while writing 5A.
        // Both operations must be accepted.

        @(negedge clk);

        wr_en   = 1'b1;
        rd_en   = 1'b1;
        data_in = 8'h5A;

        @(posedge clk);

        #1;

        wr_en = 1'b0;
        rd_en = 1'b0;

        $display(
            "SIMULTANEOUS OPERATION: READ=%h WRITE=%h COUNT=%0d",
            data_out,
            data_in,
            count
        );

        if ((data_out == 8'hA1) && (count == 15))

            $display(
                "PASS: SIMULTANEOUS READ/WRITE ACCEPTED"
            );

        else

            $display(
                "FAIL: SIMULTANEOUS READ/WRITE"
            );


        //================================================
        // TEST 10: VERIFY REMAINING FIFO ORDER
        //================================================

        $display("");
        $display("TEST 10: REMAINING FIFO ORDER");

        read_item(8'hA2);
        read_item(8'hA3);
        read_item(8'hA4);
        read_item(8'hA5);
        read_item(8'hA6);
        read_item(8'hA7);
        read_item(8'hA8);
        read_item(8'hA9);
        read_item(8'hAA);
        read_item(8'hAB);
        read_item(8'hAC);
        read_item(8'hAD);
        read_item(8'hAE);
        read_item(8'hAF);
        read_item(8'h5A);


        //================================================
        // TEST 11: EMPTY
        //================================================

        if (empty && count == 0)

            $display("PASS: FIFO EMPTY AFTER DRAIN");

        else

            $display(
                "FAIL: FIFO NOT EMPTY -> COUNT=%0d",
                count
            );


        //================================================
        // TEST 12: UNDERFLOW
        //================================================

        $display("");
        $display("TEST 12: UNDERFLOW PROTECTION");

        @(negedge clk);

        wr_en = 1'b0;
        rd_en = 1'b1;

        @(posedge clk);

        #1;

        rd_en = 1'b0;

        if (empty && count == 0)

            $display("PASS: UNDERFLOW BLOCKED");

        else

            $display("FAIL: UNDERFLOW NOT BLOCKED");


        //================================================
        // COMPLETE
        //================================================

        $display("");
        $display("==============================================");
        $display("PARAMETERIZED FIFO VERIFICATION COMPLETE");
        $display("==============================================");

        $finish;

    end

endmodule