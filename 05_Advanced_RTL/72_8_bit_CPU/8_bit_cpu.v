`timescale 1ns/1ps

module cpu_8bit (
    input wire clk,
    input wire rst,

    output reg [7:0] accumulator,
    output reg [3:0] pc,
    output reg [7:0] output_data,
    output reg halted
);

    // =========================================================
    // OPCODES
    // =========================================================

    localparam OP_NOP  = 4'b0000;
    localparam OP_LDI  = 4'b0001;
    localparam OP_ADDI = 4'b0010;
    localparam OP_SUBI = 4'b0011;
    localparam OP_ANDI = 4'b0100;
    localparam OP_ORI  = 4'b0101;
    localparam OP_XORI = 4'b0110;
    localparam OP_JMP  = 4'b0111;
    localparam OP_JZ   = 4'b1000;
    localparam OP_OUT  = 4'b1001;
    localparam OP_HLT  = 4'b1111;


    // =========================================================
    // INSTRUCTION MEMORY
    // =========================================================

    reg [7:0] instruction_memory [0:15];

    reg [7:0] instruction;

    reg [3:0] opcode;
    reg [3:0] operand;


    // =========================================================
    // INITIAL PROGRAM
    // =========================================================

    initial begin

        // Address 0
        // LDI 10
        instruction_memory[0] = 8'b0001_1010;

        // Address 1
        // ADDI 5
        instruction_memory[1] = 8'b0010_0101;

        // Address 2
        // SUBI 3
        instruction_memory[2] = 8'b0011_0011;

        // Address 3
        // ANDI 15
        instruction_memory[3] = 8'b0100_1111;

        // Address 4
        // ORI 3
        instruction_memory[4] = 8'b0101_0011;

        // Address 5
        // XORI 1
        instruction_memory[5] = 8'b0110_0001;

        // Address 6
        // OUT
        instruction_memory[6] = 8'b1001_0000;

        // Address 7
        // HLT
        instruction_memory[7] = 8'b1111_0000;

        // Remaining memory = NOP
        instruction_memory[8]  = 8'b0000_0000;
        instruction_memory[9]  = 8'b0000_0000;
        instruction_memory[10] = 8'b0000_0000;
        instruction_memory[11] = 8'b0000_0000;
        instruction_memory[12] = 8'b0000_0000;
        instruction_memory[13] = 8'b0000_0000;
        instruction_memory[14] = 8'b0000_0000;
        instruction_memory[15] = 8'b0000_0000;

    end


    // =========================================================
    // INSTRUCTION FETCH
    // =========================================================

    always @(*) begin

        instruction = instruction_memory[pc];

        opcode = instruction[7:4];

        operand = instruction[3:0];

    end


    // =========================================================
    // CPU EXECUTION
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            accumulator <= 8'd0;

            pc <= 4'd0;

            output_data <= 8'd0;

            halted <= 1'b0;

        end

        else if (!halted) begin

            case (opcode)

                // =================================================
                // NOP
                // =================================================

                OP_NOP: begin

                    pc <= pc + 1'b1;

                end


                // =================================================
                // LOAD IMMEDIATE
                // ACC = operand
                // =================================================

                OP_LDI: begin

                    accumulator <= {4'b0000, operand};

                    pc <= pc + 1'b1;

                end


                // =================================================
                // ADD IMMEDIATE
                // ACC = ACC + operand
                // =================================================

                OP_ADDI: begin

                    accumulator <= accumulator + operand;

                    pc <= pc + 1'b1;

                end


                // =================================================
                // SUBTRACT IMMEDIATE
                // ACC = ACC - operand
                // =================================================

                OP_SUBI: begin

                    accumulator <= accumulator - operand;

                    pc <= pc + 1'b1;

                end


                // =================================================
                // AND IMMEDIATE
                // =================================================

                OP_ANDI: begin

                    accumulator <= accumulator & {4'b0000, operand};

                    pc <= pc + 1'b1;

                end


                // =================================================
                // OR IMMEDIATE
                // =================================================

                OP_ORI: begin

                    accumulator <= accumulator | {4'b0000, operand};

                    pc <= pc + 1'b1;

                end


                // =================================================
                // XOR IMMEDIATE
                // =================================================

                OP_XORI: begin

                    accumulator <= accumulator ^ {4'b0000, operand};

                    pc <= pc + 1'b1;

                end


                // =================================================
                // JUMP
                // =================================================

                OP_JMP: begin

                    pc <= operand;

                end


                // =================================================
                // JUMP IF ZERO
                // =================================================

                OP_JZ: begin

                    if (accumulator == 8'd0)

                        pc <= operand;

                    else

                        pc <= pc + 1'b1;

                end


                // =================================================
                // OUTPUT
                // =================================================

                OP_OUT: begin

                    output_data <= accumulator;

                    pc <= pc + 1'b1;

                end


                // =================================================
                // HALT
                // =================================================

                OP_HLT: begin

                    halted <= 1'b1;

                end


                // =================================================
                // UNKNOWN OPCODE
                // =================================================

                default: begin

                    pc <= pc + 1'b1;

                end

            endcase

        end

    end

endmodule