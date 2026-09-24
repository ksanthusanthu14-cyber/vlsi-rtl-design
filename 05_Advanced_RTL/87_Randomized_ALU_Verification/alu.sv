`timescale 1ns/1ps

module alu #(
    parameter int WIDTH = 8
)(
    input  logic [WIDTH-1:0] A,
    input  logic [WIDTH-1:0] B,
    input  logic [3:0]       opcode,

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

        case (opcode)

            //========================================
            // ADD
            //========================================

            4'b0000: begin

                temp   = {1'b0, A} + {1'b0, B};
                result = temp[WIDTH-1:0];
                carry  = temp[WIDTH];

                overflow =
                    (~(A[WIDTH-1] ^ B[WIDTH-1])) &
                    (result[WIDTH-1] ^ A[WIDTH-1]);

            end


            //========================================
            // SUB
            //========================================

            4'b0001: begin

                result = A - B;

                carry = (A >= B);

                overflow =
                    (A[WIDTH-1] ^ B[WIDTH-1]) &
                    (result[WIDTH-1] ^ A[WIDTH-1]);

            end


            //========================================
            // AND
            //========================================

            4'b0010: begin

                result = A & B;

            end


            //========================================
            // OR
            //========================================

            4'b0011: begin

                result = A | B;

            end


            //========================================
            // XOR
            //========================================

            4'b0100: begin

                result = A ^ B;

            end


            //========================================
            // NOT
            //========================================

            4'b0101: begin

                result = ~A;

            end


            //========================================
            // SHIFT LEFT
            //========================================

            4'b0110: begin

                result = A << 1;
                carry  = A[WIDTH-1];

            end


            //========================================
            // SHIFT RIGHT
            //========================================

            4'b0111: begin

                result = A >> 1;
                carry  = A[0];

            end


            //========================================
            // INCREMENT
            //========================================

            4'b1000: begin

                temp   = {1'b0, A} + 1'b1;
                result = temp[WIDTH-1:0];
                carry  = temp[WIDTH];

            end


            //========================================
            // DECREMENT
            //========================================

            4'b1001: begin

                result = A - 1'b1;
                carry  = (A != 0);

            end


            //========================================
            // INVALID OPCODE
            //========================================

            default: begin

                result   = '0;
                carry    = 1'b0;
                overflow = 1'b0;

            end

        endcase


        //============================================
        // ZERO FLAG
        //============================================

        zero = (result == '0);

    end

endmodule