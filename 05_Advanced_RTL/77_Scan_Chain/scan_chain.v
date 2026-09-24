`timescale 1ns/1ps

module scan_chain #(
    parameter WIDTH = 4
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             scan_en,

    input  wire             scan_in,
    output wire             scan_out,

    input  wire [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);

    integer i;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            q <= {WIDTH{1'b0}};

        end

        else if (scan_en) begin

            // Serial shift:
            // scan_in -> q[0] -> q[1] -> ... -> q[WIDTH-1]

            q[0] <= scan_in;

            for (i = 1; i < WIDTH; i = i + 1) begin
                q[i] <= q[i-1];
            end

        end

        else begin

            // Normal parallel operation

            q <= d;

        end

    end

    // Last flip-flop is the serial output

    assign scan_out = q[WIDTH-1];

endmodule