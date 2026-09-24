`timescale 1ns/1ps

module advanced_elevator_controller #(
    parameter NUM_FLOORS = 4,
    parameter MOVE_TIME  = 2,
    parameter DOOR_TIME  = 2
)(
    input wire clk,
    input wire rst,
    input wire enable,

    input wire [NUM_FLOORS-1:0] floor_request,
    input wire door_obstruction,

    output reg [1:0] current_floor,

    output reg moving_up,
    output reg moving_down,

    output reg door_open,
    output reg door_closed,

    output reg [3:0] state,
    output reg [15:0] timer,

    output reg [NUM_FLOORS-1:0] pending_requests
);

    // =========================================================
    // STATE DEFINITIONS
    // =========================================================

    localparam STATE_IDLE        = 4'd0;
    localparam STATE_MOVE_UP     = 4'd1;
    localparam STATE_MOVE_DOWN   = 4'd2;
    localparam STATE_DOOR_OPEN   = 4'd3;
    localparam STATE_DOOR_WAIT   = 4'd4;
    localparam STATE_DOOR_CLOSE  = 4'd5;

    reg [3:0] next_state;

    reg [NUM_FLOORS-1:0] request_combined;

    integer state_limit;


    // =========================================================
    // COMBINE STORED AND NEW REQUESTS
    // =========================================================

    always @(*) begin
        request_combined = pending_requests | floor_request;
    end


    // =========================================================
    // STATE REGISTER + TIMER
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state <= STATE_IDLE;
            timer <= 16'd0;

        end

        else if (!enable) begin

            state <= STATE_IDLE;
            timer <= 16'd0;

        end

        else begin

            if (state != next_state) begin

                state <= next_state;
                timer <= 16'd0;

            end
            else begin

                if (state_limit > 0) begin

                    if (timer < state_limit)
                        timer <= timer + 1'b1;

                end
                else begin

                    timer <= 16'd0;

                end
            end
        end

    end


    // =========================================================
    // REQUEST STORAGE
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            pending_requests <= 4'b0000;

        end

        else if (!enable) begin

            pending_requests <= 4'b0000;

        end

        else begin

            // Add new requests
            pending_requests <= pending_requests | floor_request;

            // Clear request when door opens
            if (state == STATE_DOOR_OPEN) begin

                if (current_floor == 2'd0)
                    pending_requests[0] <= 1'b0;

                else if (current_floor == 2'd1)
                    pending_requests[1] <= 1'b0;

                else if (current_floor == 2'd2)
                    pending_requests[2] <= 1'b0;

                else if (current_floor == 2'd3)
                    pending_requests[3] <= 1'b0;

            end

        end

    end


    // =========================================================
    // FLOOR POSITION
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            current_floor <= 2'd0;

        end

        else if (!enable) begin

            current_floor <= 2'd0;

        end

        else begin

            if (state == STATE_MOVE_UP) begin

                if (timer >= MOVE_TIME - 1) begin

                    if (current_floor < NUM_FLOORS - 1)
                        current_floor <= current_floor + 1'b1;

                end

            end

            else if (state == STATE_MOVE_DOWN) begin

                if (timer >= MOVE_TIME - 1) begin

                    if (current_floor > 0)
                        current_floor <= current_floor - 1'b1;

                end

            end

        end

    end


    // =========================================================
    // STATE TIME LIMIT
    // =========================================================

    always @(*) begin

        case (state)

            STATE_MOVE_UP:
                state_limit = MOVE_TIME - 1;

            STATE_MOVE_DOWN:
                state_limit = MOVE_TIME - 1;

            STATE_DOOR_WAIT:
                state_limit = DOOR_TIME - 1;

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

            // =================================================
            // IDLE
            // =================================================

            STATE_IDLE: begin

                // Request at current floor
                if (
                    ((current_floor == 2'd0) && request_combined[0]) ||
                    ((current_floor == 2'd1) && request_combined[1]) ||
                    ((current_floor == 2'd2) && request_combined[2]) ||
                    ((current_floor == 2'd3) && request_combined[3])
                ) begin

                    next_state = STATE_DOOR_OPEN;

                end

                // Request above current floor
                else if (
                    ((current_floor == 2'd0) &&
                     (request_combined[3:1] != 3'b000)) ||

                    ((current_floor == 2'd1) &&
                     (request_combined[3:2] != 2'b00)) ||

                    ((current_floor == 2'd2) &&
                     request_combined[3])
                ) begin

                    next_state = STATE_MOVE_UP;

                end

                // Request below current floor
                else if (
                    ((current_floor == 2'd1) &&
                     request_combined[0]) ||

                    ((current_floor == 2'd2) &&
                     (request_combined[1:0] != 2'b00)) ||

                    ((current_floor == 2'd3) &&
                     (request_combined[2:0] != 3'b000))
                ) begin

                    next_state = STATE_MOVE_DOWN;

                end

            end


            // =================================================
            // MOVE UP
            // =================================================

            STATE_MOVE_UP: begin

                if (timer >= MOVE_TIME - 1) begin

                    // Current floor is requested
                    if (
                        ((current_floor == 2'd0) && request_combined[0]) ||
                        ((current_floor == 2'd1) && request_combined[1]) ||
                        ((current_floor == 2'd2) && request_combined[2]) ||
                        ((current_floor == 2'd3) && request_combined[3])
                    ) begin

                        next_state = STATE_DOOR_OPEN;

                    end

                    // Continue upward
                    else if (
                        ((current_floor == 2'd0) &&
                         (request_combined[3:1] != 3'b000)) ||

                        ((current_floor == 2'd1) &&
                         (request_combined[3:2] != 2'b00)) ||

                        ((current_floor == 2'd2) &&
                         request_combined[3])
                    ) begin

                        next_state = STATE_MOVE_UP;

                    end

                    // Otherwise handle remaining requests
                    else if (request_combined != 4'b0000) begin

                        next_state = STATE_MOVE_DOWN;

                    end

                    else begin

                        next_state = STATE_IDLE;

                    end

                end

            end


            // =================================================
            // MOVE DOWN
            // =================================================

            STATE_MOVE_DOWN: begin

                if (timer >= MOVE_TIME - 1) begin

                    // Current floor requested
                    if (
                        ((current_floor == 2'd0) && request_combined[0]) ||
                        ((current_floor == 2'd1) && request_combined[1]) ||
                        ((current_floor == 2'd2) && request_combined[2]) ||
                        ((current_floor == 2'd3) && request_combined[3])
                    ) begin

                        next_state = STATE_DOOR_OPEN;

                    end

                    // Continue downward
                    else if (
                        ((current_floor == 2'd1) &&
                         request_combined[0]) ||

                        ((current_floor == 2'd2) &&
                         (request_combined[1:0] != 2'b00)) ||

                        ((current_floor == 2'd3) &&
                         (request_combined[2:0] != 3'b000))
                    ) begin

                        next_state = STATE_MOVE_DOWN;

                    end

                    // Remaining requests
                    else if (request_combined != 4'b0000) begin

                        next_state = STATE_MOVE_UP;

                    end

                    else begin

                        next_state = STATE_IDLE;

                    end

                end

            end


            // =================================================
            // DOOR OPEN
            // =================================================

            STATE_DOOR_OPEN: begin

                next_state = STATE_DOOR_WAIT;

            end


            // =================================================
            // DOOR WAIT
            // =================================================

            STATE_DOOR_WAIT: begin

                if (door_obstruction) begin

                    next_state = STATE_DOOR_WAIT;

                end

                else if (timer >= DOOR_TIME - 1) begin

                    next_state = STATE_DOOR_CLOSE;

                end

            end


            // =================================================
            // DOOR CLOSE
            // =================================================

            STATE_DOOR_CLOSE: begin

                if (door_obstruction)
                    next_state = STATE_DOOR_OPEN;

                else
                    next_state = STATE_IDLE;

            end


            default: begin

                next_state = STATE_IDLE;

            end

        endcase

    end


    // =========================================================
    // OUTPUT DECODE
    // =========================================================

    always @(*) begin

        moving_up   = 1'b0;
        moving_down = 1'b0;

        door_open   = 1'b0;
        door_closed = 1'b1;

        case (state)

            STATE_MOVE_UP: begin

                moving_up   = 1'b1;
                moving_down = 1'b0;

            end


            STATE_MOVE_DOWN: begin

                moving_up   = 1'b0;
                moving_down = 1'b1;

            end


            STATE_DOOR_OPEN: begin

                door_open   = 1'b1;
                door_closed = 1'b0;

            end


            STATE_DOOR_WAIT: begin

                door_open   = 1'b1;
                door_closed = 1'b0;

            end


            STATE_DOOR_CLOSE: begin

                door_open   = 1'b0;
                door_closed = 1'b1;

            end


            default: begin

                moving_up   = 1'b0;
                moving_down = 1'b0;

                door_open   = 1'b0;
                door_closed = 1'b1;

            end

        endcase

    end

endmodule