`timescale 1ns/1ps

module apb_gpio (
    input  logic        clk,
    input  logic        rst,

    input  logic        psel,
    input  logic        penable,
    input  logic        pwrite,
    input  logic [7:0]  paddr,
    input  logic [31:0] pwdata,

    output logic [31:0] prdata,
    output logic        pready,

    output logic [7:0]  gpio_out
);

    logic [7:0] gpio_direction;

    assign pready = psel && penable;

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            gpio_out       <= 8'h00;
            gpio_direction <= 8'h00;
        end

        else begin

            if (psel && penable && pwrite) begin

                case (paddr)

                    8'h00:
                        gpio_out <= pwdata[7:0];

                    8'h04:
                        gpio_direction <= pwdata[7:0];

                    default:
                        begin
                        end

                endcase

            end

        end

    end


    always_comb begin

        prdata = 32'h00000000;

        if (psel && penable && !pwrite) begin

            case (paddr)

                8'h00:
                    prdata = {24'h000000, gpio_out};

                8'h04:
                    prdata = {24'h000000, gpio_direction};

                default:
                    prdata = 32'h00000000;

            endcase

        end

    end

endmodule