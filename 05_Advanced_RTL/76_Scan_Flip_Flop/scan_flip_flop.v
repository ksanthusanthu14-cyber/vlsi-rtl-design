`timescale 1ns/1ps

module scan_flip_flop (
    input  wire clk,
    input  wire rst,
    input  wire scan_en,
    input  wire d,
    input  wire si,
    output reg  q
);

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            q <= 1'b0;
        end

        else if (scan_en) begin
            q <= si;
        end

        else begin
            q <= d;
        end

    end

endmodule