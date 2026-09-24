`timescale 1ns/1ps

module apb_master #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input  logic                  pclk,
    input  logic                  presetn,

    // Transaction interface
    input  logic                  start,
    input  logic                  write_en,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,

    output logic [DATA_WIDTH-1:0] rdata,
    output logic                  busy,
    output logic                  done,
    output logic                  error,

    // APB interface
    output logic                  psel,
    output logic                  penable,
    output logic                  pwrite,
    output logic [ADDR_WIDTH-1:0] paddr,
    output logic [DATA_WIDTH-1:0] pwdata,

    input  logic [DATA_WIDTH-1:0] prdata,
    input  logic                  pready,
    input  logic                  pslverr
);

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } state_t;

    state_t state;

    always @(posedge pclk) begin

        if (!presetn) begin

            state   <= IDLE;

            busy    <= 1'b0;
            done    <= 1'b0;
            error   <= 1'b0;

            rdata   <= 0;

            psel    <= 1'b0;
            penable <= 1'b0;
            pwrite  <= 1'b0;

            paddr   <= 0;
            pwdata  <= 0;

        end

        else begin

            done <= 1'b0;

            case (state)

                // ------------------------------------------------
                // IDLE
                // ------------------------------------------------

                IDLE: begin

                    psel    <= 1'b0;
                    penable <= 1'b0;

                    if (start) begin

                        state <= SETUP;

                        busy <= 1'b1;

                        pwrite <= write_en;

                        paddr <= addr;

                        pwdata <= wdata;

                    end

                end


                // ------------------------------------------------
                // SETUP
                // ------------------------------------------------

                SETUP: begin

                    psel    <= 1'b1;
                    penable <= 1'b0;

                    state <= ACCESS;

                end


                // ------------------------------------------------
                // ACCESS
                // ------------------------------------------------

                ACCESS: begin

                    psel    <= 1'b1;
                    penable <= 1'b1;

                    if (pready) begin

                        rdata <= prdata;

                        error <= pslverr;

                        done <= 1'b1;

                        busy <= 1'b0;

                        psel <= 1'b0;
                        penable <= 1'b0;

                        state <= IDLE;

                    end

                end

                default: begin

                    state <= IDLE;

                    busy <= 1'b0;

                    psel <= 1'b0;
                    penable <= 1'b0;

                end

            endcase

        end

    end

endmodule