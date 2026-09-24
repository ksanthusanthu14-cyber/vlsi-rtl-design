`timescale 1ns/1ps

module mini_risc_cpu (

    input  logic        clk,
    input  logic        rst,

    // ============================================================
    // INSTRUCTION MEMORY INTERFACE
    // ============================================================

    output logic [7:0]  imem_addr,
    input  logic [15:0] imem_instruction,

    // ============================================================
    // DATA MEMORY INTERFACE
    // ============================================================

    output logic        dmem_read,
    output logic        dmem_write,
    output logic [7:0]  dmem_addr,
    output logic [7:0]  dmem_write_data,
    input  logic [7:0]  dmem_read_data,

    // ============================================================
    // STATUS
    // ============================================================

    output logic        halted,

    // ============================================================
    // DEBUG
    // ============================================================

    output logic [7:0]  debug_pc,
    output logic [7:0]  debug_alu_result

);


    // ============================================================
    // OPCODES
    // ============================================================

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


    // ============================================================
    // ALU CONTROL
    // ============================================================

    localparam ALU_ADD = 3'b000;
    localparam ALU_SUB = 3'b001;
    localparam ALU_AND = 3'b010;
    localparam ALU_OR  = 3'b011;
    localparam ALU_XOR = 3'b100;


    // ============================================================
    // PROGRAM COUNTER
    // ============================================================

    logic [7:0] pc;

    logic halted_reg;


    // ============================================================
    // INSTRUCTION FIELDS
    // ============================================================

    logic [3:0] opcode;

    logic [2:0] rd;
    logic [2:0] rs1;
    logic [2:0] rs2;

    logic [5:0] imm6;
    logic [8:0] imm9;

    logic signed [5:0] branch_offset;

    logic [7:0] jump_address;


    // ============================================================
    // INSTRUCTION DECODE
    // ============================================================

    always_comb begin

        opcode = imem_instruction[15:12];

        rd  = imem_instruction[11:9];

        rs1 = imem_instruction[8:6];

        rs2 = imem_instruction[5:3];

        imm6 = imem_instruction[5:0];

        imm9 = imem_instruction[8:0];

        branch_offset = imem_instruction[5:0];

        jump_address = imem_instruction[7:0];

    end


    // ============================================================
    // REGISTER FILE
    //
    // IMPORTANT:
    //
    // R-type / ADDI / BEQ:
    //     first source = rs1 [8:6]
    //
    // STORE:
    //     source register = rd field [11:9]
    //
    // This is because STORE uses:
    //
    // [15:12] opcode
    // [11:9]  source register
    // [8:0]   address
    // ============================================================

    logic [7:0] reg_data1;
    logic [7:0] reg_data2;

    logic [7:0] reg_write_data;

    logic reg_write;

    logic [2:0] register_read_addr1;


    always_comb begin

        if (opcode == OP_STORE)
            register_read_addr1 = rd;
        else
            register_read_addr1 = rs1;

    end


    register_file u_register_file (

        .clk        (clk),
        .rst        (rst),

        .read_addr1 (register_read_addr1),
        .read_addr2 (rs2),

        .write_addr (rd),
        .write_data (reg_write_data),

        .reg_write  (reg_write),

        .read_data1 (reg_data1),
        .read_data2 (reg_data2)

    );


    // ============================================================
    // CONTROL UNIT
    // ============================================================

    logic       alu_src_imm;
    logic       mem_read;
    logic       mem_write;
    logic       mem_to_reg;
    logic       branch;
    logic       jump;
    logic       halt;

    logic [2:0] alu_control;


    control_unit u_control (

        .opcode       (opcode),

        .reg_write   (reg_write),
        .alu_src_imm (alu_src_imm),

        .mem_read    (mem_read),
        .mem_write   (mem_write),

        .mem_to_reg  (mem_to_reg),

        .branch      (branch),
        .jump        (jump),
        .halt        (halt),

        .alu_control (alu_control)

    );


    // ============================================================
    // ALU SECOND INPUT
    // ============================================================

    logic [7:0] alu_b;


    always_comb begin

        case (opcode)

            OP_ADDI:
                alu_b = {2'b00, imm6};

            OP_LOAD:
                alu_b = imm9[7:0];

            OP_STORE:
                alu_b = 8'd0;

            default:
                alu_b = reg_data2;

        endcase

    end


    // ============================================================
    // ALU
    // ============================================================

    logic [7:0] alu_result;

    logic alu_zero;


    alu u_alu (

        .a           (reg_data1),
        .b           (alu_b),

        .alu_control (alu_control),

        .result      (alu_result),
        .zero        (alu_zero)

    );


    // ============================================================
    // DATA MEMORY INTERFACE
    // ============================================================

    always_comb begin

        dmem_read = mem_read;

        dmem_write = mem_write;

        // For STORE, reg_data1 is now correctly the STORE source
        // register because register_read_addr1 selects rd.

        dmem_write_data = reg_data1;


        case (opcode)

            OP_LOAD:
                dmem_addr = imm9[7:0];

            OP_STORE:
                dmem_addr = imm9[7:0];

            default:
                dmem_addr = alu_result;

        endcase

    end


    // ============================================================
    // WRITEBACK
    // ============================================================

    always_comb begin

        case (opcode)

            OP_MOVI:
                reg_write_data = imm9[7:0];

            OP_LOAD:
                reg_write_data = dmem_read_data;

            default:
                reg_write_data = alu_result;

        endcase

    end


    // ============================================================
    // PROGRAM COUNTER / CPU CONTROL
    // ============================================================

    always_ff @(posedge clk) begin

        if (rst) begin

            pc <= 8'd0;

            halted_reg <= 1'b0;

        end

        else if (!halted_reg) begin

            // ----------------------------------------------------
            // HALT
            // ----------------------------------------------------

            if (halt) begin

                halted_reg <= 1'b1;

                pc <= pc;

            end

            // ----------------------------------------------------
            // JUMP
            // ----------------------------------------------------

            else if (jump) begin

                pc <= jump_address;

            end

            // ----------------------------------------------------
            // BRANCH IF EQUAL
            // ----------------------------------------------------

            else if (branch && alu_zero) begin

                pc <= pc + {{2{branch_offset[5]}}, branch_offset};

            end

            // ----------------------------------------------------
            // NORMAL SEQUENTIAL EXECUTION
            // ----------------------------------------------------

            else begin

                pc <= pc + 8'd1;

            end

        end

    end


    // ============================================================
    // OUTPUTS
    // ============================================================

    always_comb begin

        imem_addr = pc;

        halted = halted_reg;

        debug_pc = pc;

        debug_alu_result = alu_result;

    end


endmodule