`timescale 1ns/1ps

module alu #(
    parameter WIDTH = 8
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic [3:0]       op,

    output logic [WIDTH-1:0] result,
    output logic             carry,
    output logic             zero,
    output logic             overflow
);

    logic [WIDTH:0] temp;

    always_comb begin

        result   = '0;
        carry    = 1'b0;
        overflow = 1'b0;
        temp     = '0;

        case (op)

            // ADD
            4'b0000: begin

                temp   = {1'b0, a} + {1'b0, b};
                result = temp[WIDTH-1:0];
                carry  = temp[WIDTH];

                overflow =
                    (~(a[WIDTH-1] ^ b[WIDTH-1])) &
                    (result[WIDTH-1] ^ a[WIDTH-1]);

            end


            // SUB
            4'b0001: begin

                result = a - b;

                overflow =
                    (a[WIDTH-1] ^ b[WIDTH-1]) &
                    (result[WIDTH-1] ^ a[WIDTH-1]);

            end


            // AND
            4'b0010:
                result = a & b;


            // OR
            4'b0011:
                result = a | b;


            // XOR
            4'b0100:
                result = a ^ b;


            // NOT A
            4'b0101:
                result = ~a;


            // SHIFT LEFT
            4'b0110:
                result = a << 1;


            // SHIFT RIGHT
            4'b0111:
                result = a >> 1;


            // INCREMENT
            4'b1000:
                result = a + 1'b1;


            // DECREMENT
            4'b1001:
                result = a - 1'b1;


            default:
                result = '0;

        endcase


        zero = (result == '0);

    end

endmodule