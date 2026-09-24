`timescale 1ns/1ps

module lfsr #(
    parameter WIDTH = 4,
    parameter SEED  = 4'b0001
)(
    input  wire            clk,
    input  wire            rst,
    input  wire            enable,
    output reg [WIDTH-1:0] q
);

    wire feedback;

    // Polynomial:
    // x^4 + x^3 + 1
    //
    // Next state:
    // Qnext = {Q2, Q1, Q0, Q3 XOR Q2}
    //
    // For WIDTH = 4:
    //
    // 0001 -> 0010
    // 0010 -> 0100
    // 0100 -> 1001
    // ...
    // 1000 -> 0001

    assign feedback = q[WIDTH-1] ^ q[WIDTH-2];

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            q <= SEED;
        end

        else if (enable) begin
            q <= {
                q[WIDTH-2:0],
                feedback
            };
        end

    end

endmodule