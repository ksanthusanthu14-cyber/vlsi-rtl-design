`timescale 1ns/1ps

module pulse_synchronizer (
    input wire src_clk,
    input wire dest_clk,
    input wire rst,

    input wire pulse_in,

    output reg pulse_out
);

    // =========================================================
    // SOURCE DOMAIN
    // =========================================================

    reg src_toggle;

    always @(posedge src_clk or posedge rst) begin

        if (rst) begin

            src_toggle <= 1'b0;

        end

        else if (pulse_in) begin

            src_toggle <= ~src_toggle;

        end

    end


    // =========================================================
    // DESTINATION DOMAIN
    // =========================================================

    reg sync_ff1;
    reg sync_ff2;
    reg sync_ff2_prev;

    always @(posedge dest_clk or posedge rst) begin

        if (rst) begin

            sync_ff1    <= 1'b0;
            sync_ff2    <= 1'b0;
            sync_ff2_prev <= 1'b0;

            pulse_out   <= 1'b0;

        end

        else begin

            // -------------------------------------------------
            // Two-stage synchronization
            // -------------------------------------------------

            sync_ff1 <= src_toggle;

            sync_ff2 <= sync_ff1;


            // -------------------------------------------------
            // Save previous synchronized toggle
            // -------------------------------------------------

            sync_ff2_prev <= sync_ff2;


            // -------------------------------------------------
            // Detect toggle
            // -------------------------------------------------

            if (sync_ff2 != sync_ff2_prev)

                pulse_out <= 1'b1;

            else

                pulse_out <= 1'b0;

        end

    end

endmodule