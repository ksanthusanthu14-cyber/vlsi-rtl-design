`timescale 1ns/1ps

module watchdog_timer #(
    parameter WIDTH = 8
)(
    input wire             clk,
    input wire             rst,

    input wire             enable,
    input wire             kick,

    input wire [WIDTH-1:0] timeout_value,

    output reg             timeout,
    output reg [WIDTH-1:0] counter
);

    // =========================================================
    // WATCHDOG TIMER
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            counter <= {WIDTH{1'b0}};

            timeout <= 1'b0;

        end

        else if (!enable) begin

            counter <= {WIDTH{1'b0}};

            timeout <= 1'b0;

        end

        // -----------------------------------------------------
        // KICK / REFRESH WATCHDOG
        // -----------------------------------------------------

        else if (kick) begin

            counter <= {WIDTH{1'b0}};

            timeout <= 1'b0;

        end

        // -----------------------------------------------------
        // WATCHDOG COUNTING
        // -----------------------------------------------------

        else begin

            if (counter >= timeout_value - 1'b1) begin

                counter <= counter;

                timeout <= 1'b1;

            end

            else begin

                counter <= counter + 1'b1;

                timeout <= 1'b0;

            end

        end

    end

endmodule