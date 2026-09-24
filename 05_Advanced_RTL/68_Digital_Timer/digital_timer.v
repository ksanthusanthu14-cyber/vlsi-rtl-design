`timescale 1ns/1ps

module digital_timer #(
    parameter CLK_DIV = 10
)(
    input  wire       clk,
    input  wire       rst,

    input  wire       load,
    input  wire       start,
    input  wire       pause,
    input  wire       clear,

    input  wire [4:0] load_hours,
    input  wire [5:0] load_minutes,
    input  wire [5:0] load_seconds,

    output reg [4:0] hours,
    output reg [5:0] minutes,
    output reg [5:0] seconds,

    output reg       running,
    output reg       done
);

    integer div_count;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            div_count <= 0;

            hours   <= 0;
            minutes <= 0;
            seconds <= 0;

            running <= 1'b0;
            done    <= 1'b0;

        end

        else begin

            // DONE is a one-clock pulse
            done <= 1'b0;


            // =================================================
            // CLEAR
            // =================================================

            if (clear) begin

                div_count <= 0;

                hours   <= 0;
                minutes <= 0;
                seconds <= 0;

                running <= 1'b0;
                done    <= 1'b0;

            end


            // =================================================
            // LOAD
            // =================================================

            else if (load) begin

                div_count <= 0;

                hours   <= load_hours;
                minutes <= load_minutes;
                seconds <= load_seconds;

                running <= 1'b0;
                done    <= 1'b0;

            end


            // =================================================
            // PAUSE
            // =================================================

            else if (pause) begin

                running   <= 1'b0;
                div_count <= 0;

            end


            // =================================================
            // START / RESUME
            // =================================================

            else if (start) begin

                if ((hours != 0) ||
                    (minutes != 0) ||
                    (seconds != 0)) begin

                    running <= 1'b1;

                end

                else begin

                    running <= 1'b0;

                end

            end


            // =================================================
            // COUNTDOWN
            // =================================================

            else if (running) begin

                if (div_count >= CLK_DIV - 1) begin

                    div_count <= 0;

                    // -----------------------------------------
                    // 00:00:01 -> 00:00:00
                    // -----------------------------------------

                    if ((hours == 0) &&
                        (minutes == 0) &&
                        (seconds == 1)) begin

                        hours   <= 0;
                        minutes <= 0;
                        seconds <= 0;

                        running <= 1'b0;
                        done    <= 1'b1;

                    end


                    // -----------------------------------------
                    // SECOND COUNTDOWN
                    // -----------------------------------------

                    else if (seconds > 0) begin

                        seconds <= seconds - 1'b1;

                    end


                    // -----------------------------------------
                    // MINUTE BORROW
                    // 00:01:00 -> 00:00:59
                    // -----------------------------------------

                    else if (minutes > 0) begin

                        seconds <= 6'd59;
                        minutes <= minutes - 1'b1;

                    end


                    // -----------------------------------------
                    // HOUR BORROW
                    // 01:00:00 -> 00:59:59
                    // -----------------------------------------

                    else if (hours > 0) begin

                        seconds <= 6'd59;
                        minutes <= 6'd59;
                        hours   <= hours - 1'b1;

                    end

                    else begin

                        running <= 1'b0;
                        done    <= 1'b1;

                    end

                end

                else begin

                    div_count <= div_count + 1;

                end

            end


            // =================================================
            // IDLE / PAUSED
            // =================================================

            else begin

                div_count <= 0;

            end

        end

    end

endmodule