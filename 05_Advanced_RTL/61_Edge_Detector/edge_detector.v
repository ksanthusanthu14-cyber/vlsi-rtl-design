`timescale 1ns/1ps

module edge_detector (
    input wire clk,
    input wire rst,
    input wire enable,

    input wire signal_in,

    output reg rising_edge,
    output reg falling_edge
);

    reg signal_prev;


    // =========================================================
    // EDGE DETECTOR
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            signal_prev <= 1'b0;

            rising_edge <= 1'b0;
            falling_edge <= 1'b0;

        end

        else if (!enable) begin

            signal_prev <= signal_in;

            rising_edge <= 1'b0;
            falling_edge <= 1'b0;

        end

        else begin

            // -------------------------------------------------
            // Detect rising edge: 0 -> 1
            // -------------------------------------------------

            if (!signal_prev && signal_in)
                rising_edge <= 1'b1;
            else
                rising_edge <= 1'b0;


            // -------------------------------------------------
            // Detect falling edge: 1 -> 0
            // -------------------------------------------------

            if (signal_prev && !signal_in)
                falling_edge <= 1'b1;
            else
                falling_edge <= 1'b0;


            // -------------------------------------------------
            // Store current signal for next clock
            // -------------------------------------------------

            signal_prev <= signal_in;

        end

    end

endmodule