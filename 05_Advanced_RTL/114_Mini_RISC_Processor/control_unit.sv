`timescale 1ns/1ps

module control_unit (

    input  logic [3:0] opcode,

    output logic       reg_write,
    output logic       alu_src_imm,
    output logic       mem_read,
    output logic       mem_write,
    output logic       mem_to_reg,
    output logic       branch,
    output logic       jump,
    output logic       halt,

    output logic [2:0] alu_control
);

    localparam OP_NOP   = 4'b0000;
    localparam OP_ADD   = 4'b0001;
    localparam OP_SUB   = 4'b0010;
    localparam OP_AND   = 4'b0011;
    localparam OP_OR    = 4'b0100;
    localparam OP_XOR   = 4'b0101;
    localparam OP_ADDI  = 4'b0110;
    localparam OP_MOVI  = 4'b0111;
    localparam OP_LOAD  = 4'b1000;
    localparam OP_STORE = 4'b1001;
    localparam OP_BEQ   = 4'b1010;
    localparam OP_JMP   = 4'b1011;
    localparam OP_HALT  = 4'b1100;

    localparam ALU_ADD  = 3'b000;
    localparam ALU_SUB  = 3'b001;
    localparam ALU_AND  = 3'b010;
    localparam ALU_OR   = 3'b011;
    localparam ALU_XOR  = 3'b100;

    always_comb begin

        reg_write   = 1'b0;
        alu_src_imm = 1'b0;
        mem_read    = 1'b0;
        mem_write   = 1'b0;
        mem_to_reg  = 1'b0;
        branch      = 1'b0;
        jump        = 1'b0;
        halt        = 1'b0;

        alu_control = ALU_ADD;

        case (opcode)

            OP_NOP: begin
            end

            OP_ADD: begin
                reg_write   = 1'b1;
                alu_control = ALU_ADD;
            end

            OP_SUB: begin
                reg_write   = 1'b1;
                alu_control = ALU_SUB;
            end

            OP_AND: begin
                reg_write   = 1'b1;
                alu_control = ALU_AND;
            end

            OP_OR: begin
                reg_write   = 1'b1;
                alu_control = ALU_OR;
            end

            OP_XOR: begin
                reg_write   = 1'b1;
                alu_control = ALU_XOR;
            end

            OP_ADDI: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                alu_control = ALU_ADD;
            end

            OP_MOVI: begin
                reg_write   = 1'b1;
                alu_src_imm = 1'b1;
                alu_control = ALU_ADD;
            end

            OP_LOAD: begin
                reg_write   = 1'b1;
                mem_read    = 1'b1;
                mem_to_reg  = 1'b1;
                alu_src_imm = 1'b1;
                alu_control = ALU_ADD;
            end

            OP_STORE: begin
                mem_write   = 1'b1;
                alu_src_imm = 1'b1;
                alu_control = ALU_ADD;
            end

            OP_BEQ: begin
                branch      = 1'b1;
                alu_control = ALU_SUB;
            end

            OP_JMP: begin
                jump = 1'b1;
            end

            OP_HALT: begin
                halt = 1'b1;
            end

            default: begin
            end

        endcase

    end

endmodule