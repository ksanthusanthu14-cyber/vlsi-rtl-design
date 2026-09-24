`timescale 1ns/1ps

module apb_timer (
    input  logic        clk,
    input  logic        rst,

    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    input  logic [7:0]  paddr,
    input  logic [31:0] pwdata,

    output logic [31:0] prdata,
    output logic        pready
);

    logic [31:0] load_value;
    logic [31:0] counter;
    logic        enable;
    logic        done;

    assign pready = psel && penable;


    // ============================================================
    // TIMER CONTROL
    // ============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            load_value <= 32'd0;
            counter    <= 32'd0;
            enable     <= 1'b0;
            done       <= 1'b0;

        end

        else begin

            // ----------------------------------------------------
            // LOAD REGISTER
            // ----------------------------------------------------

            if (psel && penable && pwrite &&
                (paddr == 8'h00)) begin

                load_value <= pwdata;

            end


            // ----------------------------------------------------
            // CONTROL REGISTER
            //
            // Writing bit 0 = 1 starts the timer.
            // Starting the timer clears DONE.
            // ----------------------------------------------------

            if (psel && penable && pwrite &&
                (paddr == 8'h08)) begin

                if (pwdata[0]) begin

                    enable <= 1'b1;
                    counter <= load_value;
                    done <= 1'b0;

                end
                else begin

                    enable <= 1'b0;

                end

            end


            // ----------------------------------------------------
            // COUNTDOWN
            // ----------------------------------------------------

            if (enable) begin

                if (counter > 0) begin

                    counter <= counter - 1'b1;

                end

                else begin

                    enable <= 1'b0;

                    // Sticky completion flag
                    done <= 1'b1;

                end

            end

        end

    end


    // ============================================================
    // APB READ
    // ============================================================

    always_comb begin

        prdata = 32'h00000000;

        if (psel && penable && !pwrite) begin

            case (paddr)

                // LOAD VALUE
                8'h00:
                    prdata = load_value;

                // CURRENT COUNTER
                8'h04:
                    prdata = counter;

                // ENABLE
                8'h08:
                    prdata = {
                        31'h00000000,
                        enable
                    };

                // DONE
                8'h0C:
                    prdata = {
                        31'h00000000,
                        done
                    };

                default:
                    prdata = 32'h00000000;

            endcase

        end

    end

endmodule