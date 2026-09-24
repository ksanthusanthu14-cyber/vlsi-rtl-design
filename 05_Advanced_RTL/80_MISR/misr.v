`timescale 1ns/1ps

module misr #(
    parameter WIDTH = 4
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             enable,

    input  wire [WIDTH-1:0] data_in,

    output reg  [WIDTH-1:0] signature
);

    wire feedback;

    // ============================================================
    // MISR feedback
    //
    // Polynomial:
    //
    // x^4 + x^3 + 1
    //
    // Feedback combines:
    //
    // signature[3]
    // signature[2]
    // data_in[3]
    //
    // ============================================================

    assign feedback =
        signature[WIDTH-1] ^
        signature[WIDTH-2] ^
        data_in[WIDTH-1];

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            signature <= {WIDTH{1'b0}};

        end

        else if (enable) begin

            // ----------------------------------------------------
            // Parallel input is XORed into the register while
            // the signature shifts.
            // ----------------------------------------------------

            signature <= {
                signature[WIDTH-2:0],
                feedback
            } ^ data_in;

        end

    end

endmodule