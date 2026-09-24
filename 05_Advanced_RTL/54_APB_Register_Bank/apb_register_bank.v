`timescale 1ns/1ps

module apb_register_bank (
    input wire        PCLK,
    input wire        PRESETn,

    input wire        PSEL,
    input wire        PENABLE,
    input wire        PWRITE,
    input wire [7:0]  PADDR,
    input wire [7:0]  PWDATA,

    output reg [7:0]  PRDATA,
    output reg        PREADY,
    output reg        PSLVERR,

    // Register outputs
    output reg [7:0]  control_reg,
    output reg [7:0]  status_reg,
    output reg [7:0]  data_reg,
    output reg [7:0]  config_reg
);

    // =========================================================
    // REGISTER MAP
    // =========================================================
    //
    // 0x00 -> CONTROL  : Read/Write
    // 0x04 -> STATUS   : Read Only
    // 0x08 -> DATA     : Read/Write
    // 0x0C -> CONFIG   : Read/Write
    //
    // =========================================================


    always @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn) begin

            control_reg <= 8'h00;
            status_reg  <= 8'h01;
            data_reg    <= 8'h00;
            config_reg  <= 8'h00;

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

                // =================================================
                // WRITE
                // =================================================

                if (PWRITE) begin

                    case (PADDR)

                        // CONTROL - Read/Write
                        8'h00: begin
                            control_reg <= PWDATA;
                        end

                        // STATUS - Read Only
                        8'h04: begin
                            PSLVERR <= 1'b1;
                        end

                        // DATA - Read/Write
                        8'h08: begin
                            data_reg <= PWDATA;
                        end

                        // CONFIG - Read/Write
                        8'h0C: begin
                            config_reg <= PWDATA;
                        end

                        // Invalid address
                        default: begin
                            PSLVERR <= 1'b1;
                        end

                    endcase
                end

                // =================================================
                // READ
                // =================================================

                else begin

                    case (PADDR)

                        // CONTROL
                        8'h00: begin
                            PRDATA <= control_reg;
                        end

                        // STATUS
                        8'h04: begin
                            PRDATA <= status_reg;
                        end

                        // DATA
                        8'h08: begin
                            PRDATA <= data_reg;
                        end

                        // CONFIG
                        8'h0C: begin
                            PRDATA <= config_reg;
                        end

                        // Invalid address
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