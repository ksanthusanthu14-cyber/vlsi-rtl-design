`timescale 1ns/1ps

module cdc_synchronizer (
    input wire dest_clk,
    input wire rst,

    input wire async_signal,

    output reg sync_out
);

    // =========================================================
    // TWO-STAGE CDC SYNCHRONIZER
    // =========================================================

    reg sync_ff1;

    always @(posedge dest_clk or posedge rst) begin

        if (rst) begin

            sync_ff1 <= 1'b0;
            sync_out <= 1'b0;

        end

        else begin

            // First synchronization stage
            sync_ff1 <= async_signal;

            // Second synchronization stage
            sync_out <= sync_ff1;

        end

    end

endmodule