`timescale 1ns/1ps

module cpu_8bit_single_cycle (
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
    localparam OP_ADD  = 4'b0001;
    localparam OP_SUB  = 4'b0010;
    localparam OP_AND  = 4'b0011;
    localparam OP_OR   = 4'b0100;
    localparam OP_XOR  = 4'b0101;
    localparam OP_LDI  = 4'b0110;
    localparam OP_LD   = 4'b0111;
    localparam OP_ST   = 4'b1000;
    localparam OP_ADDI = 4'b1001;
    localparam OP_SUBI = 4'b1010;
    localparam OP_JMP  = 4'b1011;
    localparam OP_BEQZ = 4'b1100;
    localparam OP_OUT  = 4'b1101;
    localparam OP_HLT  = 4'b1111;


    // =========================================================
    // REGISTER FILE
    // =========================================================

    reg [7:0] registers [0:3];


    // =========================================================
    // DATA MEMORY
    // =========================================================

    reg [7:0] data_memory [0:15];


    // =========================================================
    // INSTRUCTION MEMORY
    // =========================================================

    reg [15:0] instruction_memory [0:15];


    // =========================================================
    // CPU INTERNAL SIGNALS
    // =========================================================

    reg [15:0] instruction;

    reg [3:0] opcode;

    reg [1:0] rd;

    reg [1:0] rs;

    reg [7:0] immediate;

    reg [3:0] address;

    integer i;


    // =========================================================
    // INITIALIZATION
    // =========================================================

    initial begin

        // Clear register file
        for (i = 0; i < 4; i = i + 1)
            registers[i] = 8'd0;

        // Clear data memory
        for (i = 0; i < 16; i = i + 1)
            data_memory[i] = 8'd0;

        // -----------------------------------------------------
        // DATA MEMORY
        // -----------------------------------------------------

        data_memory[0] = 8'd25;


        // -----------------------------------------------------
        // PROGRAM
        // -----------------------------------------------------

        // 0: LDI R0, 10
        instruction_memory[0] =
            16'b0110_00_00_00001010;

        // 1: LDI R1, 5
        instruction_memory[1] =
            16'b0110_01_00_00000101;

        // 2: ADD R0, R1
        instruction_memory[2] =
            16'b0001_00_01_00000000;

        // 3: SUBI R0, 3
        instruction_memory[3] =
            16'b1010_00_00_00000011;

        // 4: LDI R2, 25
        instruction_memory[4] =
            16'b0110_10_00_00011001;

        // 5: ST R2, address 1
        instruction_memory[5] =
            16'b1000_10_00_00000001;

        // 6: LD R3, address 0
        instruction_memory[6] =
            16'b0111_11_00_00000000;

        // 7: OUT R0
        instruction_memory[7] =
            16'b1101_00_00_00000000;

        // 8: HLT
        instruction_memory[8] =
            16'b1111_00_00_00000000;


        // Remaining instructions = NOP

        instruction_memory[9]  = 16'd0;
        instruction_memory[10] = 16'd0;
        instruction_memory[11] = 16'd0;
        instruction_memory[12] = 16'd0;
        instruction_memory[13] = 16'd0;
        instruction_memory[14] = 16'd0;
        instruction_memory[15] = 16'd0;

    end


    // =========================================================
    // INSTRUCTION DECODE
    // =========================================================

    always @(*) begin

        instruction = instruction_memory[pc];

        opcode = instruction[15:12];

        rd = instruction[11:10];

        rs = instruction[9:8];

        immediate = instruction[7:0];

        address = instruction[3:0];

    end


    // =========================================================
    // CPU EXECUTION
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            pc <= 4'd0;

            accumulator <= 8'd0;

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
                // ADD
                // =================================================

                OP_ADD: begin

                    registers[rd] <=
                        registers[rd] + registers[rs];

                    pc <= pc + 1'b1;

                end


                // =================================================
                // SUB
                // =================================================

                OP_SUB: begin

                    registers[rd] <=
                        registers[rd] - registers[rs];

                    pc <= pc + 1'b1;

                end


                // =================================================
                // AND
                // =================================================

                OP_AND: begin

                    registers[rd] <=
                        registers[rd] & registers[rs];

                    pc <= pc + 1'b1;

                end


                // =================================================
                // OR
                // =================================================

                OP_OR: begin

                    registers[rd] <=
                        registers[rd] | registers[rs];

                    pc <= pc + 1'b1;

                end


                // =================================================
                // XOR
                // =================================================

                OP_XOR: begin

                    registers[rd] <=
                        registers[rd] ^ registers[rs];

                    pc <= pc + 1'b1;

                end


                // =================================================
                // LOAD IMMEDIATE
                // =================================================

                OP_LDI: begin

                    registers[rd] <= immediate;

                    pc <= pc + 1'b1;

                end


                // =================================================
                // LOAD FROM MEMORY
                // =================================================

                OP_LD: begin

                    registers[rd] <= data_memory[address];

                    pc <= pc + 1'b1;

                end


                // =================================================
                // STORE TO MEMORY
                // =================================================

                OP_ST: begin

                    data_memory[address] <= registers[rd];

                    pc <= pc + 1'b1;

                end


                // =================================================
                // ADD IMMEDIATE
                // =================================================

                OP_ADDI: begin

                    registers[rd] <=
                        registers[rd] + immediate;

                    pc <= pc + 1'b1;

                end


                // =================================================
                // SUBTRACT IMMEDIATE
                // =================================================

                OP_SUBI: begin

                    registers[rd] <=
                        registers[rd] - immediate;

                    pc <= pc + 1'b1;

                end


                // =================================================
                // JUMP
                // =================================================

                OP_JMP: begin

                    pc <= address;

                end


                // =================================================
                // BRANCH IF ZERO
                // =================================================

                OP_BEQZ: begin

                    if (registers[rd] == 8'd0)

                        pc <= address;

                    else

                        pc <= pc + 1'b1;

                end


                // =================================================
                // OUTPUT
                // =================================================

                OP_OUT: begin

                    accumulator <= registers[rd];

                    output_data <= registers[rd];

                    pc <= pc + 1'b1;

                end


                // =================================================
                // HALT
                // =================================================

                OP_HLT: begin

                    halted <= 1'b1;

                end


                // =================================================
                // DEFAULT
                // =================================================

                default: begin

                    pc <= pc + 1'b1;

                end

            endcase

        end

    end

endmodule