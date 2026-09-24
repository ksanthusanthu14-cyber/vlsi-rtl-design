`timescale 1ns/1ps

module apb_master (
    input  wire        PCLK,
    input  wire        PRESETn,

    // Control from testbench/system
    input  wire        start,
    input  wire        write,
    input  wire [7:0]  address,
    input  wire [7:0]  write_data,

    // Response from APB slave
    input  wire [7:0]  read_data,
    input  wire        PREADY,
    input  wire        PSLVERR,

    // APB interface
    output reg         PSEL,
    output reg         PENABLE,
    output reg         PWRITE,
    output reg [7:0]   PADDR,
    output reg [7:0]   PWDATA,

    // Result/status
    output reg [7:0]   read_data_out,
    output reg         busy,
    output reg         done,
    output reg         error
);

    localparam IDLE   = 2'b00;
    localparam SETUP  = 2'b01;
    localparam ACCESS = 2'b10;

    reg [1:0] state;

    always @(posedge PCLK or negedge PRESETn) begin

        if (!PRESETn) begin

            state        <= IDLE;

            PSEL         <= 1'b0;
            PENABLE      <= 1'b0;
            PWRITE       <= 1'b0;
            PADDR        <= 8'h00;
            PWDATA        <= 8'h00;

            read_data_out <= 8'h00;

            busy         <= 1'b0;
            done         <= 1'b0;
            error        <= 1'b0;

        end else begin

            // Default: done is a one-cycle pulse
            done <= 1'b0;

            case (state)

                IDLE: begin

                    PSEL    <= 1'b0;
                    PENABLE <= 1'b0;
                    busy    <= 1'b0;
                    error   <= 1'b0;

                    if (start) begin

                        PADDR  <= address;
                        PWDATA <= write_data;
                        PWRITE <= write;

                        PSEL   <= 1'b1;
                        busy   <= 1'b1;

                        state  <= SETUP;
                    end
                end

                SETUP: begin

                    // APB setup phase
                    PSEL    <= 1'b1;
                    PENABLE <= 1'b0;

                    state <= ACCESS;
                end

                ACCESS: begin

                    // APB access phase
                    PSEL    <= 1'b1;
                    PENABLE <= 1'b1;

                    if (PREADY) begin

                        if (!PWRITE)
                            read_data_out <= read_data;

                        error <= PSLVERR;
                        done  <= 1'b1;
                        busy  <= 1'b0;

                        PSEL    <= 1'b0;
                        PENABLE <= 1'b0;

                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule