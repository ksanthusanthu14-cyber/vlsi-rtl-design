`timescale 1ns/1ps

module fifo_tb;

    localparam int DATA_WIDTH = 8;
    localparam int DEPTH      = 8;

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

    fifo #(
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

    task automatic fifo_write(
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

    task automatic fifo_read(
        input logic [DATA_WIDTH-1:0] expected
    );

        begin

            @(negedge clk);

            wr_en = 1'b0;
            rd_en = 1'b1;

            @(posedge clk);

            #1;

            if (data_out === expected) begin

                $display(
                    "PASS: READ DATA = %h | EXPECTED = %h | COUNT = %0d",
                    data_out,
                    expected,
                    count
                );

            end

            else begin

                $display(
                    "FAIL: READ DATA = %h | EXPECTED = %h | COUNT = %0d",
                    data_out,
                    expected,
                    count
                );

            end

            rd_en = 1'b0;

        end

    endtask


    //==================================================
    // TEST SEQUENCE
    //==================================================

    initial begin

        $dumpfile("fifo.vcd");
        $dumpvars(0, fifo_tb);


        // Initial values
        rst     = 1'b1;
        wr_en   = 1'b0;
        rd_en   = 1'b0;
        data_in = '0;


        //================================================
        // RESET
        //================================================

        #12;

        rst = 1'b0;

        #1;

        $display("");
        $display("==============================================");
        $display("SYSTEMVERILOG FIFO VERIFICATION");
        $display("==============================================");


        //================================================
        // TEST 1: RESET / EMPTY
        //================================================

        if (empty && !full && count == 0)

            $display("PASS: RESET -> FIFO EMPTY");

        else

            $display("FAIL: RESET -> FIFO STATUS ERROR");


        //================================================
        // TEST 2: WRITE DATA
        //================================================

        $display("");
        $display("TEST 2: WRITE DATA");

        fifo_write(8'hA1);
        fifo_write(8'hB2);
        fifo_write(8'hC3);
        fifo_write(8'hD4);

        #1;

        if (count == 4)
            $display("PASS: COUNT AFTER 4 WRITES = %0d", count);
        else
            $display("FAIL: COUNT AFTER WRITES = %0d", count);


        //================================================
        // TEST 3: READ DATA
        //================================================

        $display("");
        $display("TEST 3: READ DATA");

        fifo_read(8'hA1);
        fifo_read(8'hB2);
        fifo_read(8'hC3);
        fifo_read(8'hD4);


        //================================================
        // TEST 4: EMPTY FLAG
        //================================================

        @(negedge clk);

        #1;

        if (empty)

            $display("PASS: FIFO EMPTY AFTER ALL READS");

        else

            $display("FAIL: FIFO NOT EMPTY");


        //================================================
        // TEST 5: FILL FIFO
        //================================================

        $display("");
        $display("TEST 5: FILL FIFO");

        fifo_write(8'h10);
        fifo_write(8'h20);
        fifo_write(8'h30);
        fifo_write(8'h40);
        fifo_write(8'h50);
        fifo_write(8'h60);
        fifo_write(8'h70);
        fifo_write(8'h80);

        #1;

        if (full && count == DEPTH)

            $display(
                "PASS: FIFO FULL -> COUNT = %0d",
                count
            );

        else

            $display(
                "FAIL: FIFO FULL TEST -> COUNT = %0d",
                count
            );


        //================================================
        // TEST 6: OVERFLOW PROTECTION
        //================================================

        $display("");
        $display("TEST 6: OVERFLOW PROTECTION");

        @(negedge clk);

        wr_en   = 1'b1;
        rd_en   = 1'b0;
        data_in = 8'hFF;

        @(posedge clk);

        #1;

        wr_en = 1'b0;

        if (count == DEPTH)

            $display(
                "PASS: OVERFLOW BLOCKED -> COUNT = %0d",
                count
            );

        else

            $display(
                "FAIL: OVERFLOW NOT BLOCKED -> COUNT = %0d",
                count
            );


        //================================================
        // TEST 7: READ FULL FIFO
        //================================================

        $display("");
        $display("TEST 7: READ FULL FIFO");

        fifo_read(8'h10);
        fifo_read(8'h20);
        fifo_read(8'h30);
        fifo_read(8'h40);
        fifo_read(8'h50);
        fifo_read(8'h60);
        fifo_read(8'h70);
        fifo_read(8'h80);


        //================================================
        // TEST 8: UNDERFLOW PROTECTION
        //================================================

        $display("");
        $display("TEST 8: UNDERFLOW PROTECTION");

        @(negedge clk);

        rd_en = 1'b1;
        wr_en = 1'b0;

        @(posedge clk);

        #1;

        rd_en = 1'b0;

        if (empty && count == 0)

            $display(
                "PASS: UNDERFLOW BLOCKED -> COUNT = %0d",
                count
            );

        else

            $display(
                "FAIL: UNDERFLOW NOT BLOCKED -> COUNT = %0d",
                count
            );


        //================================================
        // TEST 9: FIFO ORDER
        //================================================

        $display("");
        $display("TEST 9: FIFO ORDER");

        fifo_write(8'h11);
        fifo_write(8'h22);
        fifo_write(8'h33);

        fifo_read(8'h11);
        fifo_read(8'h22);
        fifo_read(8'h33);


        //================================================
        // COMPLETE
        //================================================

        $display("");
        $display("==============================================");
        $display("SYSTEMVERILOG FIFO VERIFICATION COMPLETE");
        $display("==============================================");

        $finish;

    end

endmodule