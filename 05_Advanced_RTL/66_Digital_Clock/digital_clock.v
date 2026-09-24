`timescale 1ns/1ps

module digital_clock #(
    parameter CLK_DIV = 10
)(
    input  wire clk,
    input  wire rst,
    input  wire enable,

    output reg [5:0] seconds,
    output reg [5:0] minutes,
    output reg [4:0] hours
);

    integer div_count;

    // =========================================================
    // CLOCK DIVIDER + DIGITAL CLOCK
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            div_count <= 0;

            seconds <= 0;
            minutes <= 0;
            hours   <= 0;

        end

        else if (!enable) begin

            div_count <= 0;

        end

        else begin

            // -------------------------------------------------
            // Generate one clock tick every CLK_DIV cycles
            // -------------------------------------------------

            if (div_count >= CLK_DIV - 1) begin

                div_count <= 0;

                // =============================================
                // SECOND COUNTER
                // =============================================

                if (seconds >= 59) begin

                    seconds <= 0;

                    // =========================================
                    // MINUTE COUNTER
                    // =========================================

                    if (minutes >= 59) begin

                        minutes <= 0;

                        // =====================================
                        // HOUR COUNTER
                        // =====================================

                        if (hours >= 23)
                            hours <= 0;
                        else
                            hours <= hours + 1'b1;

                    end

                    else begin

                        minutes <= minutes + 1'b1;

                    end

                end

                else begin

                    seconds <= seconds + 1'b1;

                end

            end

            else begin

                div_count <= div_count + 1;

            end

        end

    end

endmodule