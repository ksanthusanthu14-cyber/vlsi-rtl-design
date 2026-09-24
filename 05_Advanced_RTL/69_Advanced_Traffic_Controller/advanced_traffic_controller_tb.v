`timescale 1ns/1ps

module advanced_traffic_controller_tb;

    // =========================================================
    // CLOCK
    // =========================================================

    reg clk;
    reg rst;
    reg enable;
    reg pedestrian_req;


    // =========================================================
    // OUTPUTS
    // =========================================================

    wire road_a_red;
    wire road_a_yellow;
    wire road_a_green;

    wire road_b_red;
    wire road_b_yellow;
    wire road_b_green;

    wire ped_walk;
    wire ped_stop;

    wire [3:0] state;
    wire [15:0] timer;


    // =========================================================
    // DUT
    // Small values make simulation fast
    // =========================================================

    advanced_traffic_controller #(
        .GREEN_TIME(4),
        .YELLOW_TIME(2),
        .ALL_RED_TIME(1),
        .PED_TIME(3)
    ) dut (

        .clk(clk),
        .rst(rst),
        .enable(enable),
        .pedestrian_req(pedestrian_req),

        .road_a_red(road_a_red),
        .road_a_yellow(road_a_yellow),
        .road_a_green(road_a_green),

        .road_b_red(road_b_red),
        .road_b_yellow(road_b_yellow),
        .road_b_green(road_b_green),

        .ped_walk(ped_walk),
        .ped_stop(ped_stop),

        .state(state),
        .timer(timer)
    );


    // =========================================================
    // CLOCK GENERATION
    // =========================================================

    always #5 clk = ~clk;


    // =========================================================
    // STATE NAME FUNCTION
    // =========================================================

    function [127:0] state_name;

        input [3:0] state_value;

        begin

            case (state_value)

                4'd0: state_name = "A_GREEN";
                4'd1: state_name = "A_YELLOW";
                4'd2: state_name = "ALL_RED1";
                4'd3: state_name = "B_GREEN";
                4'd4: state_name = "B_YELLOW";
                4'd5: state_name = "ALL_RED2";
                4'd6: state_name = "PED_WALK";
                4'd7: state_name = "PED_CLEAR";

                default:
                    state_name = "UNKNOWN";

            endcase

        end

    endfunction


    // =========================================================
    // SAFETY CHECK TASK
    // =========================================================

    task check_safety;

        begin

            // Both roads must never be green
            if (road_a_green && road_b_green) begin
                $display("ERROR: BOTH ROADS GREEN!");
                $finish;
            end


            // Green and yellow cannot be active together
            if (road_a_green && road_a_yellow) begin
                $display("ERROR: ROAD A GREEN + YELLOW!");
                $finish;
            end


            if (road_b_green && road_b_yellow) begin
                $display("ERROR: ROAD B GREEN + YELLOW!");
                $finish;
            end


            // Pedestrian walk only when both roads are red
            if (ped_walk && (!road_a_red || !road_b_red)) begin
                $display("ERROR: PEDESTRIAN WALK WITH ROAD ACTIVE!");
                $finish;
            end


            // Pedestrian signals must be complementary
            if (ped_walk == ped_stop) begin
                $display("ERROR: INVALID PEDESTRIAN SIGNAL!");
                $finish;
            end

        end

    endtask


    // =========================================================
    // DISPLAY
    // =========================================================

    always @(posedge clk) begin

        #1;

        $display(
            "TIME=%0t | STATE=%s | TIMER=%0d | A(RYG)=%b%b%b | B(RYG)=%b%b%b | PED(W/S)=%b/%b",
            $time,
            state_name(state),
            timer,
            road_a_red,
            road_a_yellow,
            road_a_green,
            road_b_red,
            road_b_yellow,
            road_b_green,
            ped_walk,
            ped_stop
        );

        check_safety();

    end


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        $dumpfile("advanced_traffic_controller.vcd");
        $dumpvars(0, advanced_traffic_controller_tb);


        // Initial values
        clk = 0;
        rst = 1;
        enable = 0;
        pedestrian_req = 0;


        // -----------------------------------------------------
        // RESET
        // -----------------------------------------------------

        #12;

        rst = 0;
        enable = 1;


        #1;

        if (state != 4'd0) begin
            $display("FAIL: RESET STATE IS NOT A_GREEN");
            $finish;
        end
        else begin
            $display("PASS: RESET | ROAD A GREEN");
        end


        // -----------------------------------------------------
        // RUN NORMAL TRAFFIC CYCLE
        // -----------------------------------------------------

        repeat (12)
            @(posedge clk);


        // -----------------------------------------------------
        // PEDESTRIAN REQUEST
        // -----------------------------------------------------

        $display("");
        $display("========== PEDESTRIAN REQUEST ==========");

        @(negedge clk);
        pedestrian_req = 1;

        @(negedge clk);
        pedestrian_req = 0;


        // Wait until pedestrian walk
        wait (state == 4'd6);

        #1;

        if (ped_walk &&
            road_a_red &&
            road_b_red) begin

            $display(
                "PASS: PEDESTRIAN WALK | BOTH ROADS RED"
            );

        end
        else begin

            $display(
                "FAIL: PEDESTRIAN WALK CONDITION"
            );

            $finish;

        end


        // -----------------------------------------------------
        // WAIT FOR PEDESTRIAN CLEAR
        // -----------------------------------------------------

        wait (state == 4'd7);

        #1;

        if (!ped_walk &&
            ped_stop &&
            road_a_red &&
            road_b_red) begin

            $display(
                "PASS: PEDESTRIAN CLEAR | BOTH ROADS RED"
            );

        end
        else begin

            $display(
                "FAIL: PEDESTRIAN CLEAR CONDITION"
            );

            $finish;

        end


        // -----------------------------------------------------
        // WAIT FOR ROAD A GREEN AGAIN
        // -----------------------------------------------------

        wait (state == 4'd0);

        #1;

        if (road_a_green &&
            road_b_red) begin

            $display(
                "PASS: TRAFFIC CYCLE RESUMED | ROAD A GREEN"
            );

        end
        else begin

            $display(
                "FAIL: TRAFFIC CYCLE DID NOT RESUME"
            );

            $finish;

        end


        // -----------------------------------------------------
        // DISABLE TEST
        // -----------------------------------------------------

        enable = 0;

        @(posedge clk);
        #1;

        if (state == 4'd0) begin

            $display(
                "PASS: DISABLE | CONTROLLER RETURNED TO A_GREEN"
            );

        end
        else begin

            $display(
                "FAIL: DISABLE BEHAVIOR"
            );

            $finish;

        end


        // -----------------------------------------------------
        // FINAL
        // -----------------------------------------------------

        $display("");
        $display("==============================================");
        $display("ALL ADVANCED TRAFFIC CONTROLLER TESTS PASSED");
        $display("==============================================");

        $finish;

    end

endmodule