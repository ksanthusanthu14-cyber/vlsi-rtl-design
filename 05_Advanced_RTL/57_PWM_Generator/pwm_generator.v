`timescale 1ns/1ps

module pwm_generator #(
    parameter PERIOD = 100
)(
    input wire       clk,
    input wire       rst,
    input wire       enable,

    // Duty cycle from 0 to 100
    input wire [7:0] duty_cycle,

    output reg       pwm_out
);

    // =========================================================
    // COUNTER
    // =========================================================

    integer counter;

    // =========================================================
    // PWM GENERATOR
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            counter <= 0;
            pwm_out <= 1'b0;

        end

        else if (!enable) begin

            counter <= 0;
            pwm_out <= 1'b0;

        end

        else begin

            // -------------------------------------------------
            // PWM COUNTER
            // -------------------------------------------------

            if (counter >= PERIOD - 1) begin

                counter <= 0;

            end

            else begin

                counter <= counter + 1;
                
            end


            // -------------------------------------------------
            // DUTY CYCLE COMPARISON
            // -------------------------------------------------

            if (duty_cycle == 0) begin

                pwm_out <= 1'b0;

            end

            else if (duty_cycle >= 100) begin

                pwm_out <= 1'b1;

            end

            else if (counter < ((PERIOD * duty_cycle) / 100)) begin

                pwm_out <= 1'b1;

            end

            else begin

                pwm_out <= 1'b0;

            end

        end

    end

endmodule