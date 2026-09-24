`timescale 1ns/1ps

module advanced_elevator_controller_tb;

    reg clk;
    reg rst;
    reg enable;

    reg [3:0] floor_request;
    reg door_obstruction;

    wire [1:0] current_floor;

    wire moving_up;
    wire moving_down;

    wire door_open;
    wire door_closed;

    wire [3:0] state;
    wire [15:0] timer;

    wire [3:0] pending_requests;


    // =========================================================
    // DUT
    // =========================================================

    advanced_elevator_controller #(
        .NUM_FLOORS(4),
        .MOVE_TIME(2),
        .DOOR_TIME(2)
    ) dut (

        .clk(clk),
        .rst(rst),
        .enable(enable),

        .floor_request(floor_request),
        .door_obstruction(door_obstruction),

        .current_floor(current_floor),

        .moving_up(moving_up),
        .moving_down(moving_down),

        .door_open(door_open),
        .door_closed(door_closed),

        .state(state),
        .timer(timer),

        .pending_requests(pending_requests)
    );


    // =========================================================
    // CLOCK
    // =========================================================

    always #5 clk = ~clk;


    // =========================================================
    // STATE NAMES
    // =========================================================

    function [127:0] state_name;

        input [3:0] state_value;

        begin

            case (state_value)

                4'd0: state_name = "IDLE";
                4'd1: state_name = "MOVE_UP";
                4'd2: state_name = "MOVE_DOWN";
                4'd3: state_name = "DOOR_OPEN";
                4'd4: state_name = "DOOR_WAIT";
                4'd5: state_name = "DOOR_CLOSE";

                default:
                    state_name = "UNKNOWN";

            endcase

        end

    endfunction


    // =========================================================
    // DISPLAY
    // =========================================================

    always @(posedge clk) begin

        #1;

        $display(
            "TIME=%0t | FLOOR=%0d | STATE=%s | TIMER=%0d | UP=%b DOWN=%b | DOOR_OPEN=%b DOOR_CLOSED=%b | REQUEST=%b",
            $time,
            current_floor,
            state_name(state),
            timer,
            moving_up,
            moving_down,
            door_open,
            door_closed,
            pending_requests
        );

    end


    // =========================================================
    // SAFETY CHECKS
    // =========================================================

    always @(negedge clk) begin

        // Elevator cannot move in both directions
        if (moving_up && moving_down) begin

            $display("ERROR: MOVING UP AND DOWN!");
            $finish;

        end


        // Door cannot be open while moving
        if ((moving_up || moving_down) && door_open) begin

            $display("ERROR: DOOR OPEN WHILE MOVING!");
            $finish;

        end

    end


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        $dumpfile("advanced_elevator_controller.vcd");
        $dumpvars(0, advanced_elevator_controller_tb);


        clk = 0;
        rst = 1;
        enable = 0;
        floor_request = 4'b0000;
        door_obstruction = 0;


        // =====================================================
        // RESET
        // =====================================================

        #12;

        rst = 0;
        enable = 1;

        #1;

        if (current_floor == 0 &&
            state == 0 &&
            door_closed) begin

            $display(
                "PASS: RESET | FLOOR 0 | IDLE | DOOR CLOSED"
            );

        end
        else begin

            $display("FAIL: RESET");
            $finish;

        end


        // =====================================================
        // REQUEST FLOOR 2
        // =====================================================

        $display("");
        $display("========== REQUEST FLOOR 2 ==========");

        @(negedge clk);

        floor_request = 4'b0100;

        @(negedge clk);

        floor_request = 4'b0000;


        // Wait until floor 2
        wait (current_floor == 2);

        #1;

        if (current_floor == 2) begin

            $display(
                "PASS: ELEVATOR REACHED FLOOR 2"
            );

        end
        else begin

            $display(
                "FAIL: FLOOR 2 NOT REACHED"
            );

            $finish;

        end


        // =====================================================
        // DOOR OPEN
        // =====================================================

        wait (state == 3);

        #1;

        if (door_open &&
            !moving_up &&
            !moving_down) begin

            $display(
                "PASS: FLOOR 2 | DOOR OPEN"
            );

        end
        else begin

            $display(
                "FAIL: DOOR OPEN"
            );

            $finish;

        end


        // =====================================================
        // DOOR CLOSE
        // =====================================================

        wait (state == 5);

        #1;

        if (door_closed &&
            !door_open) begin

            $display(
                "PASS: FLOOR 2 | DOOR CLOSING"
            );

        end
        else begin

            $display(
                "FAIL: DOOR CLOSE"
            );

            $finish;

        end


        // =====================================================
        // REQUEST FLOOR 3
        // =====================================================

        $display("");
        $display("========== REQUEST FLOOR 3 ==========");

        @(negedge clk);

        floor_request = 4'b1000;

        @(negedge clk);

        floor_request = 4'b0000;


        wait (current_floor == 3);

        #1;

        if (current_floor == 3) begin

            $display(
                "PASS: ELEVATOR REACHED FLOOR 3"
            );

        end
        else begin

            $display(
                "FAIL: FLOOR 3 NOT REACHED"
            );

            $finish;

        end


        // =====================================================
        // REQUEST FLOOR 1
        // =====================================================

        $display("");
        $display("========== REQUEST FLOOR 1 ==========");

        @(negedge clk);

        floor_request = 4'b0010;

        @(negedge clk);

        floor_request = 4'b0000;


        wait (current_floor == 1);

        #1;

        if (current_floor == 1) begin

            $display(
                "PASS: ELEVATOR REACHED FLOOR 1"
            );

        end
        else begin

            $display(
                "FAIL: FLOOR 1 NOT REACHED"
            );

            $finish;

        end


        // =====================================================
        // DOOR OBSTRUCTION TEST
        // =====================================================

        $display("");
        $display("========== DOOR OBSTRUCTION TEST ==========");

        wait (state == 4);

        @(negedge clk);

        door_obstruction = 1;

        repeat (3)
            @(negedge clk);

        #1;

        if (state == 4 &&
            door_open) begin

            $display(
                "PASS: DOOR OBSTRUCTION | DOOR HELD OPEN"
            );

        end
        else begin

            $display(
                "FAIL: DOOR OBSTRUCTION HANDLING"
            );

            $finish;

        end


        @(negedge clk);

        door_obstruction = 0;


        // =====================================================
        // WAIT FOR CLOSE
        // =====================================================

        wait (state == 5);

        #1;

        if (door_closed) begin

            $display(
                "PASS: OBSTRUCTION CLEARED | DOOR CAN CLOSE"
            );

        end
        else begin

            $display(
                "FAIL: DOOR DID NOT CLOSE"
            );

            $finish;

        end


        // =====================================================
        // FINAL
        // =====================================================

        $display("");
        $display("==============================================");
        $display("ALL ADVANCED ELEVATOR CONTROLLER TESTS PASSED");
        $display("==============================================");

        $finish;

    end

endmodule