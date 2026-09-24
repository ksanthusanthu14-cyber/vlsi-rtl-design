`timescale 1ns/1ps

module apb_peripheral (

    input wire        PCLK,
    input wire        PRESETn,

    // APB interface
    input wire        PSEL,
    input wire        PENABLE,
    input wire        PWRITE,
    input wire [7:0]  PADDR,
    input wire [7:0]  PWDATA,

    output reg [7:0]  PRDATA,
    output reg        PREADY,
    output reg        PSLVERR,

    // Peripheral output
    output reg [7:0]  counter_value
);

    // =========================================================
    // REGISTERS
    // =========================================================

    reg [7:0] control_reg;
    reg [7:0] data_reg;
    reg [7:0] config_reg;

    reg [7:0] counter;

    // Status
    wire counter_enable;
    wire counter_reset;

    assign counter_enable = control_reg[0];
    assign counter_reset  = control_reg[1];


    // =========================================================
    // COUNTER LOGIC
    // =========================================================

    always @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn) begin

            control_reg  <= 8'h00;
            data_reg     <= 8'h00;
            config_reg   <= 8'h0A;

            counter      <= 8'h00;
            counter_value <= 8'h00;

        end else begin

            // Load counter from DATA register
            if (counter_reset) begin

                counter <= data_reg;

            end

            // Normal counting
            else if (counter_enable) begin

                if (counter < config_reg)
                    counter <= counter + 1'b1;

            end

            counter_value <= counter;

        end

    end


    // =========================================================
    // APB REGISTER ACCESS
    // =========================================================

    always @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn) begin

            PRDATA  <= 8'h00;
            PREADY  <= 1'b0;
            PSLVERR <= 1'b0;

        end else begin

            PREADY  <= 1'b0;
            PSLVERR <= 1'b0;

            if (PSEL && PENABLE) begin

                PREADY <= 1'b1;

                // =================================================
                // WRITE
                // =================================================

                if (PWRITE) begin

                    case (PADDR)

                        // CONTROL
                        8'h00: begin
                            control_reg <= PWDATA;
                        end

                        // STATUS is read-only
                        8'h04: begin
                            PSLVERR <= 1'b1;
                        end

                        // DATA
                        8'h08: begin
                            data_reg <= PWDATA;
                        end

                        // CONFIG
                        8'h0C: begin
                            config_reg <= PWDATA;
                        end

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

                            PRDATA[0] <= counter_enable;
                            PRDATA[1] <= (counter >= config_reg);
                            PRDATA[7:2] <= counter[5:0];

                        end

                        // DATA
                        8'h08: begin
                            PRDATA <= data_reg;
                        end

                        // CONFIG
                        8'h0C: begin
                            PRDATA <= config_reg;
                        end

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