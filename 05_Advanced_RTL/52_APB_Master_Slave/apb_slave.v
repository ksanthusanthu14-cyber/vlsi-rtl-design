`timescale 1ns/1ps

module apb_slave (
    input  wire        PCLK,
    input  wire        PRESETn,

    // APB interface
    input  wire        PSEL,
    input  wire        PENABLE,
    input  wire        PWRITE,
    input  wire [7:0]  PADDR,
    input  wire [7:0]  PWDATA,

    output reg  [7:0]  PRDATA,
    output reg         PREADY,
    output reg         PSLVERR
);

    // Four APB registers
    reg [7:0] reg0;
    reg [7:0] reg1;
    reg [7:0] reg2;
    reg [7:0] reg3;

    always @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn) begin

            reg0 <= 8'h00;
            reg1 <= 8'h00;
            reg2 <= 8'h00;
            reg3 <= 8'h00;

            PRDATA  <= 8'h00;
            PREADY  <= 1'b0;
            PSLVERR <= 1'b0;

        end else begin

            // Default response
            PREADY  <= 1'b0;
            PSLVERR <= 1'b0;

            // APB ACCESS phase
            if (PSEL && PENABLE) begin

                PREADY <= 1'b1;

                if (PWRITE) begin

                    case (PADDR)

                        8'h00: reg0 <= PWDATA;
                        8'h04: reg1 <= PWDATA;
                        8'h08: reg2 <= PWDATA;
                        8'h0C: reg3 <= PWDATA;

                        default: begin
                            PSLVERR <= 1'b1;
                        end

                    endcase

                end else begin

                    case (PADDR)

                        8'h00: PRDATA <= reg0;
                        8'h04: PRDATA <= reg1;
                        8'h08: PRDATA <= reg2;
                        8'h0C: PRDATA <= reg3;

                        default: begin
                            PRDATA  <= 8'h00;
                            PSLVERR <= 1'b1;
                        end

                    endcase

                end
            end
        end
    end

endmodule