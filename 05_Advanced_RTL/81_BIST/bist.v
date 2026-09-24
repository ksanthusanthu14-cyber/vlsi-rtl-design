`timescale 1ns/1ps

module bist #(
    parameter WIDTH = 4,
    parameter SEED  = 4'b0001,
    parameter GOLDEN_SIGNATURE = 4'b0110
)(
    input wire             clk,
    input wire             rst,
    input wire             start,
    input wire             fault_inject,

    output reg             busy,
    output reg             done,
    output reg             pass,

    output reg [WIDTH-1:0] test_pattern,
    output reg [WIDTH-1:0] signature
);

    // ============================================================
    // LFSR
    // Polynomial:
    //
    // x^4 + x^3 + 1
    // ============================================================

    reg [WIDTH-1:0] lfsr_state;

    wire lfsr_feedback;

    assign lfsr_feedback =
        lfsr_state[WIDTH-1] ^
        lfsr_state[WIDTH-2];

    // ============================================================
    // MISR
    // ============================================================

    reg [WIDTH-1:0] misr_state;

    wire [WIDTH-1:0] cut_response;

    wire misr_feedback;

    // ============================================================
    // CIRCUIT UNDER TEST
    //
    // Healthy CUT:
    //
    // response = pattern XOR 1010
    //
    // Fault injection:
    //
    // invert bit 0
    // ============================================================

    assign cut_response =
        (lfsr_state ^ 4'b1010) ^
        (fault_inject ? 4'b0001 : 4'b0000);

    // ============================================================
    // MISR FEEDBACK
    // ============================================================

    assign misr_feedback =
        misr_state[WIDTH-1] ^
        misr_state[WIDTH-2] ^
        cut_response[WIDTH-1];

    // ============================================================
    // STATE MACHINE
    // ============================================================

    localparam STATE_IDLE = 2'd0;
    localparam STATE_RUN  = 2'd1;
    localparam STATE_DONE = 2'd2;

    reg [1:0] state;

    // Use 8 test patterns.
    localparam TEST_COUNT = 4'd8;

    reg [3:0] count;

    // ============================================================
    // SEQUENTIAL CONTROLLER
    // ============================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state <= STATE_IDLE;

            lfsr_state <= SEED;
            misr_state <= {WIDTH{1'b0}};

            test_pattern <= {WIDTH{1'b0}};
            signature <= {WIDTH{1'b0}};

            count <= 4'd0;

            busy <= 1'b0;
            done <= 1'b0;
            pass <= 1'b0;

        end

        else begin

            // done is a one-cycle pulse

            done <= 1'b0;

            case (state)

                // =================================================
                // IDLE
                // =================================================

                STATE_IDLE: begin

                    busy <= 1'b0;
                    pass <= 1'b0;

                    if (start) begin

                        busy <= 1'b1;

                        count <= 4'd0;

                        lfsr_state <= SEED;

                        misr_state <= 4'b0000;

                        test_pattern <= SEED;

                        state <= STATE_RUN;

                    end

                end

                // =================================================
                // RUN
                // =================================================

                STATE_RUN: begin

                    busy <= 1'b1;

                    // ---------------------------------------------
                    // Store pattern being tested
                    // ---------------------------------------------

                    test_pattern <= lfsr_state;

                    // ---------------------------------------------
                    // MISR update
                    //
                    // Response from current LFSR pattern is
                    // compressed into the MISR.
                    // ---------------------------------------------

                    misr_state <=
                        {
                            misr_state[WIDTH-2:0],
                            misr_feedback
                        } ^ cut_response;

                    // ---------------------------------------------
                    // Advance LFSR
                    // ---------------------------------------------

                    lfsr_state <= {
                        lfsr_state[WIDTH-2:0],
                        lfsr_feedback
                    };

                    // ---------------------------------------------
                    // Count test patterns
                    // ---------------------------------------------

                    if (count == TEST_COUNT - 1) begin

                        state <= STATE_DONE;

                    end

                    else begin

                        count <= count + 1'b1;

                    end

                end

                // =================================================
                // DONE
                // =================================================

                STATE_DONE: begin

                    busy <= 1'b0;

                    done <= 1'b1;

                    signature <= misr_state;

                    if (misr_state == GOLDEN_SIGNATURE)
                        pass <= 1'b1;
                    else
                        pass <= 1'b0;

                    state <= STATE_IDLE;

                end

                default: begin

                    state <= STATE_IDLE;

                end

            endcase

        end

    end

endmodule