`timescale 1ns/1ps

module advanced_traffic_controller #(
    parameter GREEN_TIME   = 5,
    parameter YELLOW_TIME  = 2,
    parameter ALL_RED_TIME = 1,
    parameter PED_TIME     = 3
)(
    input wire clk,
    input wire rst,
    input wire enable,
    input wire pedestrian_req,

    output reg road_a_red,
    output reg road_a_yellow,
    output reg road_a_green,

    output reg road_b_red,
    output reg road_b_yellow,
    output reg road_b_green,

    output reg ped_walk,
    output reg ped_stop,

    output reg [3:0] state,
    output reg [15:0] timer
);

    // =========================================================
    // STATE DEFINITIONS
    // =========================================================

    localparam STATE_A_GREEN  = 4'd0;
    localparam STATE_A_YELLOW = 4'd1;
    localparam STATE_ALL_RED1 = 4'd2;

    localparam STATE_B_GREEN  = 4'd3;
    localparam STATE_B_YELLOW = 4'd4;
    localparam STATE_ALL_RED2 = 4'd5;

    localparam STATE_PED_WALK = 4'd6;
    localparam STATE_PED_CLEAR = 4'd7;

    reg [3:0] next_state;

    reg pedestrian_pending;

    integer state_limit;


    // =========================================================
    // PEDESTRIAN REQUEST LATCH
    // =========================================================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            pedestrian_pending <= 1'b0;
        end
        else if (pedestrian_req) begin
            pedestrian_pending <= 1'b1;
        end
        else if (state == STATE_PED_CLEAR) begin
            pedestrian_pending <= 1'b0;
        end
    end


    // =========================================================
    // STATE TIMER
    // =========================================================

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_A_GREEN;
            timer <= 16'd0;
        end
        else if (!enable) begin
            state <= STATE_A_GREEN;
            timer <= 16'd0;
        end
        else begin

            if (state != next_state) begin
                state <= next_state;
                timer <= 16'd0;
            end
            else if (timer < state_limit) begin
                timer <= timer + 1'b1;
            end
        end
    end


    // =========================================================
    // STATE DURATION
    // =========================================================

    always @(*) begin

        case (state)

            STATE_A_GREEN:
                state_limit = GREEN_TIME - 1;

            STATE_A_YELLOW:
                state_limit = YELLOW_TIME - 1;

            STATE_ALL_RED1:
                state_limit = ALL_RED_TIME - 1;

            STATE_B_GREEN:
                state_limit = GREEN_TIME - 1;

            STATE_B_YELLOW:
                state_limit = YELLOW_TIME - 1;

            STATE_ALL_RED2:
                state_limit = ALL_RED_TIME - 1;

            STATE_PED_WALK:
                state_limit = PED_TIME - 1;

            STATE_PED_CLEAR:
                state_limit = ALL_RED_TIME - 1;

            default:
                state_limit = 0;

        endcase

    end


    // =========================================================
    // NEXT STATE LOGIC
    // =========================================================

    always @(*) begin

        next_state = state;

        case (state)

            // -------------------------------------------------
            // ROAD A GREEN
            // -------------------------------------------------

            STATE_A_GREEN: begin

                if (timer >= GREEN_TIME - 1)
                    next_state = STATE_A_YELLOW;

            end


            // -------------------------------------------------
            // ROAD A YELLOW
            // -------------------------------------------------

            STATE_A_YELLOW: begin

                if (timer >= YELLOW_TIME - 1)
                    next_state = STATE_ALL_RED1;

            end


            // -------------------------------------------------
            // ALL RED BEFORE ROAD B
            // -------------------------------------------------

            STATE_ALL_RED1: begin

                if (timer >= ALL_RED_TIME - 1)
                    next_state = STATE_B_GREEN;

            end


            // -------------------------------------------------
            // ROAD B GREEN
            // -------------------------------------------------

            STATE_B_GREEN: begin

                if (timer >= GREEN_TIME - 1)
                    next_state = STATE_B_YELLOW;

            end


            // -------------------------------------------------
            // ROAD B YELLOW
            // -------------------------------------------------

            STATE_B_YELLOW: begin

                if (timer >= YELLOW_TIME - 1)
                    next_state = STATE_ALL_RED2;

            end


            // -------------------------------------------------
            // ALL RED BEFORE NEXT CYCLE
            // -------------------------------------------------

            STATE_ALL_RED2: begin

                if (timer >= ALL_RED_TIME - 1) begin

                    if (pedestrian_pending)
                        next_state = STATE_PED_WALK;
                    else
                        next_state = STATE_A_GREEN;

                end

            end


            // -------------------------------------------------
            // PEDESTRIAN WALK
            // -------------------------------------------------

            STATE_PED_WALK: begin

                if (timer >= PED_TIME - 1)
                    next_state = STATE_PED_CLEAR;

            end


            // -------------------------------------------------
            // PEDESTRIAN CLEARANCE
            // -------------------------------------------------

            STATE_PED_CLEAR: begin

                if (timer >= ALL_RED_TIME - 1)
                    next_state = STATE_A_GREEN;

            end


            default:
                next_state = STATE_A_GREEN;

        endcase

    end


    // =========================================================
    // OUTPUT DECODE
    // =========================================================

    always @(*) begin

        // Default safe condition
        road_a_red    = 1'b1;
        road_a_yellow = 1'b0;
        road_a_green  = 1'b0;

        road_b_red    = 1'b1;
        road_b_yellow = 1'b0;
        road_b_green  = 1'b0;

        ped_walk = 1'b0;
        ped_stop = 1'b1;


        case (state)

            // -------------------------------------------------
            // ROAD A GREEN
            // -------------------------------------------------

            STATE_A_GREEN: begin

                road_a_red   = 1'b0;
                road_a_green = 1'b1;

                road_b_red = 1'b1;

            end


            // -------------------------------------------------
            // ROAD A YELLOW
            // -------------------------------------------------

            STATE_A_YELLOW: begin

                road_a_red    = 1'b0;
                road_a_yellow = 1'b1;

                road_b_red = 1'b1;

            end


            // -------------------------------------------------
            // ALL RED 1
            // -------------------------------------------------

            STATE_ALL_RED1: begin

                road_a_red = 1'b1;
                road_b_red = 1'b1;

            end


            // -------------------------------------------------
            // ROAD B GREEN
            // -------------------------------------------------

            STATE_B_GREEN: begin

                road_a_red = 1'b1;

                road_b_red   = 1'b0;
                road_b_green = 1'b1;

            end


            // -------------------------------------------------
            // ROAD B YELLOW
            // -------------------------------------------------

            STATE_B_YELLOW: begin

                road_a_red = 1'b1;

                road_b_red    = 1'b0;
                road_b_yellow = 1'b1;

            end


            // -------------------------------------------------
            // ALL RED 2
            // -------------------------------------------------

            STATE_ALL_RED2: begin

                road_a_red = 1'b1;
                road_b_red = 1'b1;

            end


            // -------------------------------------------------
            // PEDESTRIAN WALK
            // -------------------------------------------------

            STATE_PED_WALK: begin

                road_a_red = 1'b1;
                road_b_red = 1'b1;

                ped_walk = 1'b1;
                ped_stop = 1'b0;

            end


            // -------------------------------------------------
            // PEDESTRIAN CLEARANCE
            // -------------------------------------------------

            STATE_PED_CLEAR: begin

                road_a_red = 1'b1;
                road_b_red = 1'b1;

                ped_walk = 1'b0;
                ped_stop = 1'b1;

            end

        endcase

    end

endmodule