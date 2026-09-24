`timescale 1ns/1ps

module stopwatch #(
    parameter CLK_DIV = 10
)(
    input  wire clk,
    input  wire rst,
    input  wire start_stop,

    output reg [5:0] seconds,
    output reg [5:0] minutes,
    output reg [4:0] hours,
    output reg running
);

    integer div_count;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            div_count <= 0;

            seconds <= 0;
            minutes <= 0;
            hours   <= 0;

            running <= 1'b0;

        end

        else begin

            // -------------------------------------------------
            // START / STOP CONTROL
            // -------------------------------------------------

            if (start_stop)
                running <= ~running;


            // -------------------------------------------------
            // COUNTING
            // -------------------------------------------------

            if (running) begin

                if (div_count >= CLK_DIV - 1) begin

                    div_count <= 0;

                    // -----------------------------------------
                    // SECOND
                    // -----------------------------------------

                    if (seconds >= 59) begin

                        seconds <= 0;

                        // -------------------------------------
                        // MINUTE
                        // -------------------------------------

                        if (minutes >= 59) begin

                            minutes <= 0;

                            // ---------------------------------
                            // HOUR
                            // ---------------------------------

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

            else begin

                // Stopwatch stopped
                div_count <= 0;

            end

        end

    end

endmodule