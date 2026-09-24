`timescale 1ns/1ps

module timer_peripheral #(
    parameter WIDTH = 8
)(
    input wire             clk,
    input wire             rst,

    input wire             enable,
    input wire             start,
    input wire             clear,

    input wire [WIDTH-1:0] period_value,

    output reg [WIDTH-1:0] counter,
    output reg             running,
    output reg             done
);

    // =========================================================
    // PROGRAMMABLE TIMER PERIPHERAL
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            counter <= {WIDTH{1'b0}};
            running <= 1'b0;
            done    <= 1'b0;

        end

        else if (!enable) begin

            counter <= {WIDTH{1'b0}};
            running <= 1'b0;
            done    <= 1'b0;

        end

        else if (clear) begin

            counter <= {WIDTH{1'b0}};
            running <= 1'b0;
            done    <= 1'b0;

        end

        else if (start) begin

            // Load the programmed timer value
            counter <= period_value;
            running <= 1'b1;
            done    <= 1'b0;

        end

        else if (running) begin

            if (counter > 1) begin

                counter <= counter - 1'b1;

            end

            else begin

                counter <= {WIDTH{1'b0}};
                running <= 1'b0;
                done    <= 1'b1;

            end

        end

    end

endmodule