`timescale 1ns/1ps

module prbs_generator #(
    parameter WIDTH = 4,
    parameter SEED  = 4'b0001
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             enable,

    output reg              prbs_bit,
    output reg [WIDTH-1:0]  state
);

    wire feedback;

    // ============================================================
    // 4-bit PRBS / LFSR
    //
    // Polynomial:
    //
    // x^4 + x^3 + 1
    //
    // Next state:
    //
    // {state[2:0], state[3] ^ state[2]}
    // ============================================================

    assign feedback =
        state[WIDTH-1] ^ state[WIDTH-2];

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            state <= SEED;

            // Output corresponding to current seed
            prbs_bit <= SEED[WIDTH-1];

        end

        else if (enable) begin

            // Output the current MSB

            prbs_bit <= state[WIDTH-1];

            // Advance LFSR

            state <= {
                state[WIDTH-2:0],
                feedback
            };

        end

    end

endmodule