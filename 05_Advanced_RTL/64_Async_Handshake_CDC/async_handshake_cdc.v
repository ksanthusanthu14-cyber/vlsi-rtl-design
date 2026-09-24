`timescale 1ns/1ps

module async_handshake_cdc (

    input wire src_clk,
    input wire dest_clk,
    input wire rst,

    // Source-domain request
    input wire src_req,

    // Destination-domain event
    output reg dest_event,

    // Source-domain busy status
    output reg src_busy

);

    // =========================================================
    // SOURCE DOMAIN
    // =========================================================

    reg req_reg;

    // ACK synchronized back into source domain
    reg ack_sync1;
    reg ack_sync2;

    always @(posedge src_clk or posedge rst) begin

        if (rst) begin

            req_reg  <= 1'b0;

            ack_sync1 <= 1'b0;
            ack_sync2 <= 1'b0;

            src_busy <= 1'b0;

        end

        else begin

            // -------------------------------------------------
            // Synchronize ACK into source clock domain
            // -------------------------------------------------

            ack_sync1 <= ack_reg;
            ack_sync2 <= ack_sync1;


            // -------------------------------------------------
            // Start a new request only when not busy
            // -------------------------------------------------

            if (src_req && !src_busy) begin

                req_reg  <= 1'b1;
                src_busy <= 1'b1;

            end


            // -------------------------------------------------
            // ACK received - request completed
            // -------------------------------------------------

            if (ack_sync2 == 1'b1) begin

                req_reg  <= 1'b0;
                src_busy <= 1'b0;

            end

        end

    end


    // =========================================================
    // DESTINATION DOMAIN
    // =========================================================

    reg req_sync1;
    reg req_sync2;

    reg ack_reg;
    reg req_sync2_prev;


    always @(posedge dest_clk or posedge rst) begin

        if (rst) begin

            req_sync1    <= 1'b0;
            req_sync2    <= 1'b0;

            req_sync2_prev <= 1'b0;

            ack_reg      <= 1'b0;

            dest_event   <= 1'b0;

        end

        else begin

            // -------------------------------------------------
            // Synchronize request into destination domain
            // -------------------------------------------------

            req_sync1 <= req_reg;
            req_sync2 <= req_sync1;


            // Default event output
            dest_event <= 1'b0;


            // -------------------------------------------------
            // Detect new request
            // -------------------------------------------------

            if (req_sync2 && !req_sync2_prev) begin

                dest_event <= 1'b1;

                ack_reg <= 1'b1;

            end


            // -------------------------------------------------
            // Wait for request to return LOW before clearing ACK
            // -------------------------------------------------

            if (!req_sync2) begin

                ack_reg <= 1'b0;

            end


            req_sync2_prev <= req_sync2;

        end

    end

endmodule