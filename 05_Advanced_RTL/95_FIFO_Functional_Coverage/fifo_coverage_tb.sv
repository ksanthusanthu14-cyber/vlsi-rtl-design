`timescale 1ns/1ps

module fifo_coverage_tb;

    localparam WIDTH = 8;
    localparam DEPTH = 8;

    //============================================================
    // DUT SIGNALS
    //============================================================

    logic clk;
    logic rst;

    logic wr_en;
    logic rd_en;

    logic [WIDTH-1:0] din;
    logic [WIDTH-1:0] dout;

    logic full;
    logic empty;

    logic [$clog2(DEPTH+1)-1:0] count;


    //============================================================
    // DUT
    //============================================================

    fifo #(
        .WIDTH(WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty),
        .count(count)
    );


    //============================================================
    // CLOCK
    //============================================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end


    //============================================================
    // COVERAGE COUNTERS
    //============================================================

    integer total_cycles;

    integer write_hits;
    integer read_hits;
    integer simultaneous_hits;
    integer idle_hits;

    integer overflow_hits;
    integer underflow_hits;

    integer empty_state_hits;
    integer full_state_hits;
    integer almost_empty_hits;
    integer almost_full_hits;


    //============================================================
    // OCCUPANCY COVERAGE
    // COUNT = 0 TO 8
    //============================================================

    integer occupancy_hits [0:8];


    //============================================================
    // OPERATION COVERAGE
    //
    // 0 = IDLE
    // 1 = READ
    // 2 = WRITE
    // 3 = BOTH
    //============================================================

    integer operation_cross [0:3];


    //============================================================
    // STATE × OPERATION COVERAGE
    //
    // STATE
    // 0 = EMPTY
    // 1 = LOW
    // 2 = NORMAL
    // 3 = HIGH
    // 4 = FULL
    //
    // OPERATION
    // 0 = IDLE
    // 1 = READ
    // 2 = WRITE
    // 3 = BOTH
    //============================================================

    integer state_operation [0:4][0:3];


    //============================================================
    // PRE-OPERATION COVERAGE INFORMATION
    //
    // These variables capture the FIFO state BEFORE the
    // requested operation occurs.
    //============================================================

    integer coverage_pre_count;
    integer coverage_op;


    //============================================================
    // SUMMARY VARIABLES
    //============================================================

    integer occupancy_bins_hit;
    integer operation_bins_hit;
    integer state_operation_bins_hit;

    integer total_coverage_bins;
    integer coverage_bins_hit;
    integer coverage_percent;

    integer i;
    integer j;


    //============================================================
    // COVERAGE UPDATE
    //
    // IMPORTANT:
    // coverage_pre_count represents FIFO occupancy BEFORE
    // the requested operation.
    //============================================================

    task automatic update_coverage;

        integer state_class;

        begin

            total_cycles = total_cycles + 1;


            //====================================================
            // OCCUPANCY
            //====================================================

            occupancy_hits[coverage_pre_count] =
                occupancy_hits[coverage_pre_count] + 1;


            //====================================================
            // FIFO STATE COVERAGE
            //====================================================

            if (coverage_pre_count == 0)
                empty_state_hits =
                    empty_state_hits + 1;


            if (coverage_pre_count == DEPTH)
                full_state_hits =
                    full_state_hits + 1;


            if (coverage_pre_count == 1)
                almost_empty_hits =
                    almost_empty_hits + 1;


            if (coverage_pre_count == DEPTH-1)
                almost_full_hits =
                    almost_full_hits + 1;


            //====================================================
            // OPERATION COVERAGE
            //====================================================

            case (coverage_op)

                // IDLE
                0: begin

                    idle_hits =
                        idle_hits + 1;

                end


                // READ
                1: begin

                    if (coverage_pre_count > 0)

                        read_hits =
                            read_hits + 1;

                    else

                        underflow_hits =
                            underflow_hits + 1;

                end


                // WRITE
                2: begin

                    if (coverage_pre_count < DEPTH)

                        write_hits =
                            write_hits + 1;

                    else

                        overflow_hits =
                            overflow_hits + 1;

                end


                // BOTH
                3: begin

                    if ((coverage_pre_count > 0) &&
                        (coverage_pre_count < DEPTH))

                        simultaneous_hits =
                            simultaneous_hits + 1;

                end

            endcase


            //====================================================
            // OPERATION CROSS
            //====================================================

            operation_cross[coverage_op] =
                operation_cross[coverage_op] + 1;


            //====================================================
            // STATE CLASSIFICATION
            //====================================================

            if (coverage_pre_count == 0)

                state_class = 0;

            else if (coverage_pre_count == 1)

                state_class = 1;

            else if ((coverage_pre_count >= 2) &&
                     (coverage_pre_count <= 6))

                state_class = 2;

            else if (coverage_pre_count == 7)

                state_class = 3;

            else

                state_class = 4;


            //====================================================
            // STATE × OPERATION
            //====================================================

            state_operation[state_class][coverage_op] =
                state_operation[state_class][coverage_op] + 1;

        end

    endtask


    //============================================================
    // WRITE TASK
    //============================================================

    task automatic fifo_write;

        input [7:0] data;

        begin

            @(negedge clk);

            // Capture state BEFORE operation
            coverage_pre_count = count;
            coverage_op = 2;

            din   = data;
            wr_en = 1;
            rd_en = 0;

            @(posedge clk);

            #1;

            wr_en = 0;

        end

    endtask


    //============================================================
    // READ TASK
    //============================================================

    task automatic fifo_read;

        begin

            @(negedge clk);

            // Capture state BEFORE operation
            coverage_pre_count = count;
            coverage_op = 1;

            wr_en = 0;
            rd_en = 1;

            @(posedge clk);

            #1;

            rd_en = 0;

        end

    endtask


    //============================================================
    // SIMULTANEOUS READ / WRITE
    //============================================================

    task automatic fifo_both;

        input [7:0] data;

        begin

            @(negedge clk);

            // Capture state BEFORE operation
            coverage_pre_count = count;
            coverage_op = 3;

            din   = data;

            wr_en = 1;
            rd_en = 1;

            @(posedge clk);

            #1;

            wr_en = 0;
            rd_en = 0;

        end

    endtask


    //============================================================
    // MAIN TEST
    //============================================================

    initial begin

        $dumpfile("fifo_coverage.vcd");
        $dumpvars(0, fifo_coverage_tb);


        //========================================================
        // INITIALIZATION
        //========================================================

        rst = 1;

        wr_en = 0;
        rd_en = 0;
        din = 0;

        coverage_pre_count = 0;
        coverage_op = 0;

        total_cycles = 0;

        write_hits = 0;
        read_hits = 0;
        simultaneous_hits = 0;
        idle_hits = 0;

        overflow_hits = 0;
        underflow_hits = 0;

        empty_state_hits = 0;
        full_state_hits = 0;
        almost_empty_hits = 0;
        almost_full_hits = 0;


        //========================================================
        // CLEAR OCCUPANCY
        //========================================================

        for (i = 0; i <= DEPTH; i = i + 1)

            occupancy_hits[i] = 0;


        //========================================================
        // CLEAR OPERATION COVERAGE
        //========================================================

        for (i = 0; i < 4; i = i + 1)

            operation_cross[i] = 0;


        //========================================================
        // CLEAR STATE × OPERATION
        //========================================================

        for (i = 0; i < 5; i = i + 1) begin

            for (j = 0; j < 4; j = j + 1)

                state_operation[i][j] = 0;

        end


        //========================================================
        // RESET
        //========================================================

        repeat(3)
            @(posedge clk);

        rst = 0;

        #1;


        //========================================================
        // INITIAL IDLE COVERAGE
        //========================================================

        coverage_pre_count = count;
        coverage_op = 0;

        update_coverage;


        //========================================================
        // TEST 1
        // EMPTY FIFO
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 1: EMPTY FIFO");
        $display("==============================================");


        // Empty + READ
        fifo_read;

        update_coverage;


        //========================================================
        // TEST 2
        // FILL FIFO
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 2: FILL FIFO");
        $display("==============================================");


        for (i = 0; i < DEPTH; i = i + 1) begin

            fifo_write(i + 8'h10);

            update_coverage;

            $display(
                "WRITE %0d: COUNT=%0d FULL=%b",
                i + 1,
                count,
                full
            );

        end


        //========================================================
        // TEST 3
        // OVERFLOW
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 3: OVERFLOW ATTEMPT");
        $display("==============================================");


        fifo_write(8'hFF);

        update_coverage;

        $display(
            "OVERFLOW ATTEMPT: COUNT=%0d FULL=%b",
            count,
            full
        );


        //========================================================
        // TEST 4
        // DRAIN FIFO
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 4: DRAIN FIFO");
        $display("==============================================");


        for (i = 0; i < DEPTH; i = i + 1) begin

            fifo_read;

            update_coverage;

            $display(
                "READ %0d: COUNT=%0d EMPTY=%b",
                i + 1,
                count,
                empty
            );

        end


        //========================================================
        // TEST 5
        // UNDERFLOW
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 5: UNDERFLOW ATTEMPT");
        $display("==============================================");


        fifo_read;

        update_coverage;

        $display(
            "UNDERFLOW ATTEMPT: COUNT=%0d EMPTY=%b",
            count,
            empty
        );


        //========================================================
        // TEST 6
        // ALMOST EMPTY
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 6: ALMOST EMPTY");
        $display("==============================================");


        fifo_write(8'hA1);
        update_coverage;

        fifo_write(8'hA2);
        update_coverage;

        fifo_read;
        update_coverage;

        $display(
            "ALMOST EMPTY STATE: COUNT=%0d",
            count
        );


        //========================================================
        // TEST 7
        // ALMOST FULL
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 7: ALMOST FULL");
        $display("==============================================");


        while (count < DEPTH-1) begin

            fifo_write(8'hB0 + count);

            update_coverage;

        end


        $display(
            "ALMOST FULL STATE: COUNT=%0d",
            count
        );


        // FULL
        fifo_write(8'hCC);

        update_coverage;

        $display(
            "FULL STATE: COUNT=%0d FULL=%b",
            count,
            full
        );


        //========================================================
        // DRAIN TO EMPTY
        //========================================================

        while (count > 0) begin

            fifo_read;

            update_coverage;

        end


        //========================================================
        // TEST 8
        // SIMULTANEOUS READ/WRITE
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 8: SIMULTANEOUS READ/WRITE");
        $display("==============================================");


        fifo_write(8'h11);
        update_coverage;

        fifo_write(8'h22);
        update_coverage;

        fifo_write(8'h33);
        update_coverage;


        for (i = 0; i < 5; i = i + 1) begin

            fifo_both(8'h80 + i);

            update_coverage;

            $display(
                "SIMULTANEOUS: COUNT=%0d",
                count
            );

        end


        //========================================================
        // TEST 9
        // BOUNDARY CROSS COVERAGE
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 9: BOUNDARY CROSS COVERAGE");
        $display("==============================================");


        //========================================================
        // EMPTY + WRITE
        //========================================================

        while (count > 0) begin

            fifo_read;

            update_coverage;

        end


        fifo_write(8'hE1);

        // IMPORTANT:
        // fifo_write already captured EMPTY before operation
        update_coverage;

        $display(
            "EMPTY + WRITE: PRE_COUNT=0 POST_COUNT=%0d",
            count
        );


        //========================================================
        // RETURN TO EMPTY
        //========================================================

        fifo_read;

        update_coverage;


        //========================================================
        // EMPTY + BOTH
        //========================================================

        fifo_both(8'hE2);

        // fifo_both captured EMPTY before operation
        update_coverage;

        $display(
            "EMPTY + BOTH: PRE_COUNT=0 POST_COUNT=%0d",
            count
        );


        //========================================================
        // RETURN TO EMPTY
        //========================================================

        fifo_read;

        update_coverage;


        //========================================================
        // FILL FIFO
        //========================================================

        while (count < DEPTH) begin

            fifo_write(8'hF0 + count);

            update_coverage;

        end


        //========================================================
        // FULL + READ
        //========================================================

        fifo_read;

        // fifo_read captured FULL before operation
        update_coverage;

        $display(
            "FULL + READ: PRE_COUNT=8 POST_COUNT=%0d",
            count
        );


        //========================================================
        // RETURN TO FULL
        //========================================================

        fifo_write(8'hFA);

        update_coverage;


        //========================================================
        // FULL + BOTH
        //========================================================

        fifo_both(8'hE3);

        // fifo_both captured FULL before operation
        update_coverage;

        $display(
            "FULL + BOTH: PRE_COUNT=8 POST_COUNT=%0d",
            count
        );


        //========================================================
        // TEST 10
        // RANDOMIZED FIFO TRAFFIC
        //========================================================

        $display("");
        $display("==============================================");
        $display("TEST 10: RANDOMIZED FIFO TRAFFIC");
        $display("==============================================");


        for (i = 0; i < 300; i = i + 1) begin

            @(negedge clk);

            // Capture PRE-operation state
            coverage_pre_count = count;

            wr_en = $random % 2;
            rd_en = $random % 2;

            din = $random;


            // Capture requested operation
            case ({wr_en, rd_en})

                2'b00:
                    coverage_op = 0;

                2'b01:
                    coverage_op = 1;

                2'b10:
                    coverage_op = 2;

                2'b11:
                    coverage_op = 3;

            endcase


            @(posedge clk);

            #1;

            update_coverage;

            wr_en = 0;
            rd_en = 0;

        end


        //========================================================
        // CALCULATE OCCUPANCY COVERAGE
        //========================================================

        occupancy_bins_hit = 0;

        for (i = 0; i <= DEPTH; i = i + 1) begin

            if (occupancy_hits[i] > 0)

                occupancy_bins_hit =
                    occupancy_bins_hit + 1;

        end


        //========================================================
        // CALCULATE OPERATION COVERAGE
        //========================================================

        operation_bins_hit = 0;

        for (i = 0; i < 4; i = i + 1) begin

            if (operation_cross[i] > 0)

                operation_bins_hit =
                    operation_bins_hit + 1;

        end


        //========================================================
        // CALCULATE STATE × OPERATION
        //========================================================

        state_operation_bins_hit = 0;

        for (i = 0; i < 5; i = i + 1) begin

            for (j = 0; j < 4; j = j + 1) begin

                if (state_operation[i][j] > 0)

                    state_operation_bins_hit =
                        state_operation_bins_hit + 1;

            end

        end


        //========================================================
        // TOTAL COVERAGE
        //========================================================

        total_coverage_bins = 33;

        coverage_bins_hit =
            occupancy_bins_hit +
            operation_bins_hit +
            state_operation_bins_hit;


        coverage_percent =
            (coverage_bins_hit * 100) /
            total_coverage_bins;


        //========================================================
        // REPORT
        //========================================================

        $display("");
        $display("==============================================");
        $display("FIFO FUNCTIONAL COVERAGE REPORT");
        $display("==============================================");

        $display(
            "TOTAL COVERAGE CYCLES = %0d",
            total_cycles
        );


        //========================================================
        // OPERATION COVERAGE
        //========================================================

        $display("");
        $display("OPERATION COVERAGE");
        $display("----------------------------------------------");

        $display(
            "WRITE HITS       = %0d",
            write_hits
        );

        $display(
            "READ HITS        = %0d",
            read_hits
        );

        $display(
            "SIMULTANEOUS     = %0d",
            simultaneous_hits
        );

        $display(
            "IDLE             = %0d",
            idle_hits
        );

        $display(
            "OVERFLOW         = %0d",
            overflow_hits
        );

        $display(
            "UNDERFLOW        = %0d",
            underflow_hits
        );


        //========================================================
        // STATE COVERAGE
        //========================================================

        $display("");
        $display("FIFO STATE COVERAGE");
        $display("----------------------------------------------");

        $display(
            "EMPTY            = %0d",
            empty_state_hits
        );

        $display(
            "ALMOST EMPTY     = %0d",
            almost_empty_hits
        );

        $display(
            "ALMOST FULL      = %0d",
            almost_full_hits
        );

        $display(
            "FULL             = %0d",
            full_state_hits
        );


        //========================================================
        // OCCUPANCY
        //========================================================

        $display("");
        $display("OCCUPANCY COVERAGE");
        $display("----------------------------------------------");

        for (i = 0; i <= DEPTH; i = i + 1) begin

            $display(
                "COUNT %0d : %0d hits",
                i,
                occupancy_hits[i]
            );

        end


        //========================================================
        // OPERATION CROSS
        //========================================================

        $display("");
        $display("OPERATION CROSS COVERAGE");
        $display("----------------------------------------------");

        $display(
            "IDLE         = %0d",
            operation_cross[0]
        );

        $display(
            "READ         = %0d",
            operation_cross[1]
        );

        $display(
            "WRITE        = %0d",
            operation_cross[2]
        );

        $display(
            "READ+WRITE   = %0d",
            operation_cross[3]
        );


        //========================================================
        // STATE × OPERATION
        //========================================================

        $display("");
        $display("STATE x OPERATION COVERAGE");
        $display("----------------------------------------------");

        $display(
            "             IDLE  READ  WRITE  BOTH"
        );

        $display("----------------------------------------------");

        $display(
            "EMPTY        %0d     %0d     %0d     %0d",
            state_operation[0][0],
            state_operation[0][1],
            state_operation[0][2],
            state_operation[0][3]
        );

        $display(
            "LOW          %0d     %0d     %0d     %0d",
            state_operation[1][0],
            state_operation[1][1],
            state_operation[1][2],
            state_operation[1][3]
        );

        $display(
            "NORMAL       %0d     %0d     %0d     %0d",
            state_operation[2][0],
            state_operation[2][1],
            state_operation[2][2],
            state_operation[2][3]
        );

        $display(
            "HIGH         %0d     %0d     %0d     %0d",
            state_operation[3][0],
            state_operation[3][1],
            state_operation[3][2],
            state_operation[3][3]
        );

        $display(
            "FULL         %0d     %0d     %0d     %0d",
            state_operation[4][0],
            state_operation[4][1],
            state_operation[4][2],
            state_operation[4][3]
        );


        //========================================================
        // FINAL SUMMARY
        //========================================================

        $display("");
        $display("==============================================");
        $display("COVERAGE SUMMARY");
        $display("==============================================");

        $display(
            "OCCUPANCY BINS HIT         = %0d / 9",
            occupancy_bins_hit
        );

        $display(
            "OPERATION BINS HIT         = %0d / 4",
            operation_bins_hit
        );

        $display(
            "STATE x OPERATION BINS HIT = %0d / 20",
            state_operation_bins_hit
        );

        $display(
            "FUNCTIONAL COVERAGE        = %0d%%",
            coverage_percent
        );

        $display("==============================================");


        if ((occupancy_bins_hit == 9) &&
            (operation_bins_hit == 4) &&
            (state_operation_bins_hit == 20)) begin

            $display(
                "OVERALL COVERAGE RESULT = 100%%"
            );

        end

        else begin

            $display(
                "OVERALL COVERAGE RESULT = INCOMPLETE"
            );

        end


        $display("==============================================");

        $display(
            "FIFO FUNCTIONAL COVERAGE VERIFICATION COMPLETE"
        );

        $finish;

    end

endmodule