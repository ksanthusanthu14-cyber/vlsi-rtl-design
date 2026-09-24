`timescale 1ns/1ps

module glitch_free_clock_mux (
    input  wire clk0,
    input  wire clk1,
    input  wire select,
    input  wire rst,
    output wire clk_out
);

    // Clock enable signals
    reg en0;
    reg en1;

    // ---------------------------------------------------------
    // Enable clock 0
    //
    // Enable changes only while clk0 is LOW.
    // ---------------------------------------------------------

    always @(negedge clk0 or posedge rst) begin

        if (rst)
            en0 <= 1'b0;

        else
            en0 <= ~select & ~en1;

    end


    // ---------------------------------------------------------
    // Enable clock 1
    //
    // Enable changes only while clk1 is LOW.
    // ---------------------------------------------------------

    always @(negedge clk1 or posedge rst) begin

        if (rst)
            en1 <= 1'b0;

        else
            en1 <= select & ~en0;

    end


    // ---------------------------------------------------------
    // Clock output
    // ---------------------------------------------------------

    assign clk_out = (clk0 & en0) | (clk1 & en1);

endmodule