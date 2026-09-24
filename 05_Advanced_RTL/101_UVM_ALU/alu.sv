module alu #(
    parameter WIDTH = 8
)(
    input  logic [WIDTH-1:0] a,
    input  logic [WIDTH-1:0] b,
    input  logic [2:0]       op,
    output logic [WIDTH-1:0] result
);

    localparam OP_ADD = 3'b000;
    localparam OP_SUB = 3'b001;
    localparam OP_AND = 3'b010;
    localparam OP_OR  = 3'b011;
    localparam OP_XOR = 3'b100;
    localparam OP_NOT = 3'b101;

    always_comb begin

        case (op)

            OP_ADD:
                result = a + b;

            OP_SUB:
                result = a - b;

            OP_AND:
                result = a & b;

            OP_OR:
                result = a | b;

            OP_XOR:
                result = a ^ b;

            OP_NOT:
                result = ~a;

            default:
                result = '0;

        endcase

    end

endmodule