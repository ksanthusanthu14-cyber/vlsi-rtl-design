`timescale 1ns/1ps

module debounce #(
    parameter COUNT_WIDTH = 4,
    parameter STABLE_COUNT = 8
)(
    input wire clk,
    input wire rst,
    input wire enable,

    input wire button_in,

    output reg button_out
);

    reg button_sync;
    reg button_last;

    reg [COUNT_WIDTH-1:0] stable_counter;


    // =========================================================
    // DEBOUNCE CIRCUIT
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            button_sync    <= 1'b0;
            button_last    <= 1'b0;
            stable_counter <= {COUNT_WIDTH{1'b0}};
            button_out     <= 1'b0;

        end

        else if (!enable) begin

            button_sync    <= 1'b0;
            button_last    <= 1'b0;
            stable_counter <= {COUNT_WIDTH{1'b0}};
            button_out     <= 1'b0;

        end

        else begin

            // -------------------------------------------------
            // Synchronize / sample input
            // -------------------------------------------------

            button_sync <= button_in;


            // -------------------------------------------------
            // Detect stable input
            // -------------------------------------------------

            if (button_sync == button_last) begin

                if (stable_counter < STABLE_COUNT) begin

                    stable_counter <= stable_counter + 1'b1;

                end

                else begin

                    button_out <= button_sync;

                end

            end

            else begin

                // Input changed - restart stability counter

                button_last    <= button_sync;

                stable_counter <= {COUNT_WIDTH{1'b0}};

            end

        end

    end

endmodule