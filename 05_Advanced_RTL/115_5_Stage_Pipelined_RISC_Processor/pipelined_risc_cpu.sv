`timescale 1ns/1ps

module pipelined_risc_cpu (

    input  logic        clk,
    input  logic        rst,

    output logic [7:0]  imem_addr,
    input  logic [15:0] imem_instruction,

    output logic        dmem_read,
    output logic        dmem_write,
    output logic [7:0]  dmem_addr,
    output logic [7:0]  dmem_write_data,
    input  logic [7:0]  dmem_read_data,

    output logic        halted,

    output logic [7:0]  debug_pc,
    output logic [7:0]  debug_ex_alu_result,
    output logic        debug_stall,
    output logic        debug_flush
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
    // ALU
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

    // ============================================================
    // WRITEBACK
    // ============================================================

    logic [2:0] wb_rd;
    logic [7:0] wb_write_data;
    logic       wb_reg_write;

    // ============================================================
    // REGISTER FILE
    // ============================================================

    logic [2:0] rf_read_addr1;
    logic [2:0] rf_read_addr2;

    logic [7:0] rf_read_data1;
    logic [7:0] rf_read_data2;

    register_file u_register_file (

        .clk        (clk),
        .rst        (rst),

        .read_addr1 (rf_read_addr1),
        .read_addr2 (rf_read_addr2),

        .write_addr (wb_rd),
        .write_data (wb_write_data),

        .reg_write  (wb_reg_write),

        .read_data1 (rf_read_data1),
        .read_data2 (rf_read_data2)

    );

    // ============================================================
    // IF / ID
    // ============================================================

    logic        if_id_valid;
    logic [7:0]  if_id_pc;
    logic [15:0] if_id_instruction;

    // ============================================================
    // ID DECODE
    // ============================================================

    logic [3:0] id_opcode;

    logic [2:0] id_rd;
    logic [2:0] id_rs1;
    logic [2:0] id_rs2;

    logic [5:0] id_imm6;
    logic [8:0] id_imm9;

    logic signed [5:0] id_branch_offset;

    logic [7:0] id_jump_address;

    always_comb begin

        id_opcode = if_id_instruction[15:12];

        id_rd  = if_id_instruction[11:9];
        id_rs1 = if_id_instruction[8:6];
        id_rs2 = if_id_instruction[5:3];

        id_imm6 = if_id_instruction[5:0];
        id_imm9 = if_id_instruction[8:0];

        id_branch_offset = if_id_instruction[5:0];

        id_jump_address = if_id_instruction[7:0];

    end

    // ============================================================
    // REGISTER FILE READ ADDRESSES
    // ============================================================

    always_comb begin

        rf_read_addr1 = 3'd0;
        rf_read_addr2 = 3'd0;

        case (id_opcode)

            OP_ADD,
            OP_SUB,
            OP_AND,
            OP_OR,
            OP_XOR: begin

                rf_read_addr1 = id_rs1;
                rf_read_addr2 = id_rs2;

            end

            OP_ADDI: begin

                rf_read_addr1 = id_rs1;

            end

            OP_BEQ: begin

                rf_read_addr1 = id_rd;
                rf_read_addr2 = id_rs1;

            end

            OP_STORE: begin

                rf_read_addr1 = id_rd;

            end

            default: begin

                rf_read_addr1 = 3'd0;
                rf_read_addr2 = 3'd0;

            end

        endcase

    end

    // ============================================================
    // CONTROL UNIT
    // ============================================================

    logic       id_reg_write;
    logic       id_alu_src_imm;
    logic       id_mem_read;
    logic       id_mem_write;
    logic       id_mem_to_reg;
    logic       id_branch;
    logic       id_jump;
    logic       id_halt;
    logic [2:0] id_alu_control;

    control_unit u_control (

        .opcode       (id_opcode),

        .reg_write   (id_reg_write),
        .alu_src_imm (id_alu_src_imm),

        .mem_read    (id_mem_read),
        .mem_write   (id_mem_write),
        .mem_to_reg  (id_mem_to_reg),

        .branch      (id_branch),
        .jump        (id_jump),
        .halt        (id_halt),

        .alu_control (id_alu_control)

    );

    // ============================================================
    // ID / EX PIPELINE REGISTER
    // ============================================================

    logic        id_ex_valid;

    logic [7:0]  id_ex_pc;
    logic [3:0]  id_ex_opcode;

    logic [2:0]  id_ex_rd;
    logic [2:0]  id_ex_rs1;
    logic [2:0]  id_ex_rs2;

    logic [7:0]  id_ex_reg_data1;
    logic [7:0]  id_ex_reg_data2;

    logic [5:0]  id_ex_imm6;
    logic [8:0]  id_ex_imm9;

    logic signed [5:0] id_ex_branch_offset;

    logic [7:0] id_ex_jump_address;

    logic       id_ex_reg_write;
    logic       id_ex_alu_src_imm;

    logic       id_ex_mem_read;
    logic       id_ex_mem_write;
    logic       id_ex_mem_to_reg;

    logic       id_ex_branch;
    logic       id_ex_jump;
    logic       id_ex_halt;

    logic [2:0] id_ex_alu_control;

    // ============================================================
    // EX / MEM PIPELINE REGISTER
    // ============================================================

    logic        ex_mem_valid;
    logic [2:0]  ex_mem_rd;
    logic        ex_mem_reg_write;

    logic [7:0]  ex_mem_alu_result;

    logic        ex_mem_mem_read;
    logic        ex_mem_mem_write;
    logic        ex_mem_mem_to_reg;

    logic [7:0]  ex_mem_store_data;

    // ============================================================
    // MEM / WB PIPELINE REGISTER
    // ============================================================

    logic        mem_wb_valid;
    logic [2:0]  mem_wb_rd;
    logic        mem_wb_reg_write;
    logic        mem_wb_mem_to_reg;

    logic [7:0]  mem_wb_alu_result;
    logic [7:0]  mem_wb_mem_data;

    logic [7:0]  mem_wb_write_data;

    always_comb begin

        if (mem_wb_mem_to_reg)
            mem_wb_write_data = mem_wb_mem_data;
        else
            mem_wb_write_data = mem_wb_alu_result;

    end

    assign wb_rd = mem_wb_rd;

    assign wb_write_data = mem_wb_write_data;

    assign wb_reg_write =
        mem_wb_valid &&
        mem_wb_reg_write;

    // ============================================================
    // EX SOURCE REGISTER IDENTIFICATION
    //
    // This is the important correction.
    //
    // R-type:
    //   A = rs1
    //   B = rs2
    //
    // ADDI:
    //   A = rs1
    //
    // STORE:
    //   A = rd field because STORE encodes source in [11:9]
    //
    // BEQ:
    //   A = rd
    //   B = rs1
    // ============================================================

    logic [2:0] ex_source_a;
    logic [2:0] ex_source_b;

    logic ex_uses_a;
    logic ex_uses_b;

    always_comb begin

        ex_source_a = 3'd0;
        ex_source_b = 3'd0;

        ex_uses_a = 1'b0;
        ex_uses_b = 1'b0;

        case (id_ex_opcode)

            OP_ADD,
            OP_SUB,
            OP_AND,
            OP_OR,
            OP_XOR: begin

                ex_source_a = id_ex_rs1;
                ex_source_b = id_ex_rs2;

                ex_uses_a = 1'b1;
                ex_uses_b = 1'b1;

            end

            OP_ADDI: begin

                ex_source_a = id_ex_rs1;

                ex_uses_a = 1'b1;

            end

            OP_STORE: begin

                // STORE R1,address
                // source register is RD field

                ex_source_a = id_ex_rd;

                ex_uses_a = 1'b1;

            end

            OP_BEQ: begin

                ex_source_a = id_ex_rd;
                ex_source_b = id_ex_rs1;

                ex_uses_a = 1'b1;
                ex_uses_b = 1'b1;

            end

            default: begin

            end

        endcase

    end

    // ============================================================
    // FORWARDING UNIT
    // ============================================================

    logic [1:0] forward_a;
    logic [1:0] forward_b;

    always_comb begin

        forward_a = 2'b00;
        forward_b = 2'b00;

        // --------------------------------------------------------
        // EX/MEM has priority
        // --------------------------------------------------------

        if (
            ex_uses_a &&
            ex_mem_valid &&
            ex_mem_reg_write &&
            !ex_mem_mem_to_reg &&
            (ex_mem_rd != 3'd0) &&
            (ex_mem_rd == ex_source_a)
        ) begin

            forward_a = 2'b10;

        end

        else if (
            ex_uses_a &&
            mem_wb_valid &&
            mem_wb_reg_write &&
            (mem_wb_rd != 3'd0) &&
            (mem_wb_rd == ex_source_a)
        ) begin

            forward_a = 2'b01;

        end


        if (
            ex_uses_b &&
            ex_mem_valid &&
            ex_mem_reg_write &&
            !ex_mem_mem_to_reg &&
            (ex_mem_rd != 3'd0) &&
            (ex_mem_rd == ex_source_b)
        ) begin

            forward_b = 2'b10;

        end

        else if (
            ex_uses_b &&
            mem_wb_valid &&
            mem_wb_reg_write &&
            (mem_wb_rd != 3'd0) &&
            (mem_wb_rd == ex_source_b)
        ) begin

            forward_b = 2'b01;

        end

    end

    // ============================================================
    // FORWARDED OPERANDS
    // ============================================================

    logic [7:0] ex_operand_a;
    logic [7:0] ex_operand_b_reg;

    always_comb begin

        case (forward_a)

            2'b10:
                ex_operand_a = ex_mem_alu_result;

            2'b01:
                ex_operand_a = mem_wb_write_data;

            default:
                ex_operand_a = id_ex_reg_data1;

        endcase

    end

    always_comb begin

        case (forward_b)

            2'b10:
                ex_operand_b_reg = ex_mem_alu_result;

            2'b01:
                ex_operand_b_reg = mem_wb_write_data;

            default:
                ex_operand_b_reg = id_ex_reg_data2;

        endcase

    end

    // ============================================================
    // STORE DATA
    // ============================================================

    logic [7:0] ex_store_data;

    always_comb begin

        ex_store_data = ex_operand_a;

    end

    // ============================================================
    // ALU B INPUT
    // ============================================================

    logic [7:0] ex_operand_b;

    always_comb begin

        case (id_ex_opcode)

            OP_ADDI:
                ex_operand_b = {2'b00, id_ex_imm6};

            OP_MOVI:
                ex_operand_b = id_ex_imm9[7:0];

            default:
                ex_operand_b = ex_operand_b_reg;

        endcase

    end

    // ============================================================
    // ALU
    // ============================================================

    logic [7:0] ex_alu_result;
    logic       ex_zero;

    alu u_alu (

        .a           (ex_operand_a),
        .b           (ex_operand_b),

        .alu_control (id_ex_alu_control),

        .result      (ex_alu_result),
        .zero        (ex_zero)

    );

    // ============================================================
    // FINAL EX RESULT
    // ============================================================

    logic [7:0] ex_result_final;

    always_comb begin

        if (id_ex_opcode == OP_MOVI)
            ex_result_final = id_ex_imm9[7:0];
        else
            ex_result_final = ex_alu_result;

    end

    // ============================================================
    // BRANCH / JUMP
    // ============================================================

    logic       branch_taken;
    logic [7:0] control_target;

    always_comb begin

        branch_taken = 1'b0;
        control_target = 8'd0;

        if (
            id_ex_valid &&
            id_ex_branch &&
            ex_zero
        ) begin

            branch_taken = 1'b1;

            control_target =
                id_ex_pc +
                {{2{id_ex_branch_offset[5]}},
                 id_ex_branch_offset};

        end

        else if (
            id_ex_valid &&
            id_ex_jump
        ) begin

            branch_taken = 1'b1;

            control_target = id_ex_jump_address;

        end

    end

    // ============================================================
    // LOAD-USE HAZARD
    // ============================================================

    logic stall;

    always_comb begin

        stall = 1'b0;

        if (
            if_id_valid &&
            id_ex_valid &&
            id_ex_mem_read &&
            (id_ex_rd != 3'd0)
        ) begin

            // ADD / SUB / AND / OR / XOR / ADDI

            if (
                (
                    (id_opcode == OP_ADD)  ||
                    (id_opcode == OP_SUB)  ||
                    (id_opcode == OP_AND)  ||
                    (id_opcode == OP_OR)   ||
                    (id_opcode == OP_XOR)  ||
                    (id_opcode == OP_ADDI)
                ) &&
                (id_rs1 == id_ex_rd)
            ) begin

                stall = 1'b1;

            end

            // BEQ

            if (
                (id_opcode == OP_BEQ) &&
                (
                    (id_rd  == id_ex_rd) ||
                    (id_rs1 == id_ex_rd)
                )
            ) begin

                stall = 1'b1;

            end

            // STORE source is RD field

            if (
                (id_opcode == OP_STORE) &&
                (id_rd == id_ex_rd)
            ) begin

                stall = 1'b1;

            end

        end

    end

    // ============================================================
    // FLUSH
    // ============================================================

    logic flush;

    assign flush = branch_taken;

    // ============================================================
    // HALT IN ID
    // ============================================================

    logic halt_in_id;

    assign halt_in_id =
        if_id_valid &&
        (id_opcode == OP_HALT);

    // ============================================================
    // DATA MEMORY
    // ============================================================

    always_comb begin

        dmem_read = 1'b0;
        dmem_write = 1'b0;

        dmem_addr = 8'd0;
        dmem_write_data = 8'd0;

        if (ex_mem_valid) begin

            dmem_read = ex_mem_mem_read;

            dmem_write = ex_mem_mem_write;

            // LOAD / STORE address
            // was placed in ex_mem_alu_result.

            dmem_addr = ex_mem_alu_result;

            dmem_write_data = ex_mem_store_data;

        end

    end

    // ============================================================
    // HALT
    // ============================================================

    logic halted_reg;

    // ============================================================
    // MAIN PIPELINE
    // ============================================================

    always_ff @(posedge clk) begin

        if (rst) begin

            pc <= 8'd0;

            // IF/ID

            if_id_valid <= 1'b0;
            if_id_pc <= 8'd0;
            if_id_instruction <= {OP_NOP, 12'b0};

            // ID/EX

            id_ex_valid <= 1'b0;
            id_ex_pc <= 8'd0;
            id_ex_opcode <= OP_NOP;

            id_ex_rd <= 3'd0;
            id_ex_rs1 <= 3'd0;
            id_ex_rs2 <= 3'd0;

            id_ex_reg_data1 <= 8'd0;
            id_ex_reg_data2 <= 8'd0;

            id_ex_imm6 <= 6'd0;
            id_ex_imm9 <= 9'd0;

            id_ex_branch_offset <= 6'sd0;
            id_ex_jump_address <= 8'd0;

            id_ex_reg_write <= 1'b0;
            id_ex_alu_src_imm <= 1'b0;

            id_ex_mem_read <= 1'b0;
            id_ex_mem_write <= 1'b0;
            id_ex_mem_to_reg <= 1'b0;

            id_ex_branch <= 1'b0;
            id_ex_jump <= 1'b0;
            id_ex_halt <= 1'b0;

            id_ex_alu_control <= ALU_ADD;

            // EX/MEM

            ex_mem_valid <= 1'b0;
            ex_mem_rd <= 3'd0;
            ex_mem_reg_write <= 1'b0;

            ex_mem_alu_result <= 8'd0;

            ex_mem_mem_read <= 1'b0;
            ex_mem_mem_write <= 1'b0;
            ex_mem_mem_to_reg <= 1'b0;

            ex_mem_store_data <= 8'd0;

            // MEM/WB

            mem_wb_valid <= 1'b0;
            mem_wb_rd <= 3'd0;
            mem_wb_reg_write <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;

            mem_wb_alu_result <= 8'd0;
            mem_wb_mem_data <= 8'd0;

            halted_reg <= 1'b0;

        end

        else if (!halted_reg) begin

            // ====================================================
            // MEM → WB
            // ====================================================

            mem_wb_valid <= ex_mem_valid;

            mem_wb_rd <= ex_mem_rd;

            mem_wb_reg_write <= ex_mem_reg_write;

            mem_wb_mem_to_reg <= ex_mem_mem_to_reg;

            mem_wb_alu_result <= ex_mem_alu_result;

            mem_wb_mem_data <= dmem_read_data;


            // ====================================================
            // EX → MEM
            // ====================================================

            ex_mem_valid <= id_ex_valid;

            ex_mem_rd <= id_ex_rd;

            ex_mem_reg_write <= id_ex_reg_write;

            // Memory instructions use immediate address.

            if (
                (id_ex_opcode == OP_LOAD) ||
                (id_ex_opcode == OP_STORE)
            ) begin

                ex_mem_alu_result <= id_ex_imm9[7:0];

            end
            else begin

                ex_mem_alu_result <= ex_result_final;

            end

            ex_mem_mem_read <= id_ex_mem_read;

            ex_mem_mem_write <= id_ex_mem_write;

            ex_mem_mem_to_reg <= id_ex_mem_to_reg;

            ex_mem_store_data <= ex_store_data;


            // ====================================================
            // HALT
            // ====================================================

            if (
                id_ex_valid &&
                id_ex_halt
            ) begin

                halted_reg <= 1'b1;

            end


            // ====================================================
            // BRANCH / JUMP FLUSH
            // ====================================================

            if (flush) begin

                pc <= control_target;

                if_id_valid <= 1'b0;
                if_id_pc <= 8'd0;
                if_id_instruction <= {OP_NOP, 12'b0};

                id_ex_valid <= 1'b0;
                id_ex_opcode <= OP_NOP;

                id_ex_reg_write <= 1'b0;

                id_ex_mem_read <= 1'b0;
                id_ex_mem_write <= 1'b0;
                id_ex_mem_to_reg <= 1'b0;

                id_ex_branch <= 1'b0;
                id_ex_jump <= 1'b0;
                id_ex_halt <= 1'b0;

            end


            // ====================================================
            // LOAD-USE STALL
            // ====================================================

            else if (stall) begin

                // Freeze PC

                pc <= pc;

                // Freeze IF/ID

                if_id_valid <= if_id_valid;
                if_id_pc <= if_id_pc;
                if_id_instruction <= if_id_instruction;

                // Insert bubble

                id_ex_valid <= 1'b0;
                id_ex_opcode <= OP_NOP;

                id_ex_reg_write <= 1'b0;

                id_ex_mem_read <= 1'b0;
                id_ex_mem_write <= 1'b0;
                id_ex_mem_to_reg <= 1'b0;

                id_ex_branch <= 1'b0;
                id_ex_jump <= 1'b0;
                id_ex_halt <= 1'b0;

            end


            // ====================================================
            // NORMAL PIPELINE
            // ====================================================

            else begin

                // IF → ID

                if_id_valid <= !halt_in_id;

                if_id_pc <= pc;

                if_id_instruction <= imem_instruction;

                // PC

                if (halt_in_id)
                    pc <= pc;
                else
                    pc <= pc + 8'd1;

                // ID → EX

                id_ex_valid <= if_id_valid;

                id_ex_pc <= if_id_pc;

                id_ex_opcode <= id_opcode;

                id_ex_rd <= id_rd;
                id_ex_rs1 <= id_rs1;
                id_ex_rs2 <= id_rs2;

                // ID-stage register-read bypass from the WB stage.
                // This closes the case where an instruction enters ID in
                // the same cycle that its source register is written back.
                if (
                    wb_reg_write &&
                    (wb_rd != 3'd0) &&
                    (wb_rd == rf_read_addr1)
                )
                    id_ex_reg_data1 <= wb_write_data;
                else
                    id_ex_reg_data1 <= rf_read_data1;

                if (
                    wb_reg_write &&
                    (wb_rd != 3'd0) &&
                    (wb_rd == rf_read_addr2)
                )
                    id_ex_reg_data2 <= wb_write_data;
                else
                    id_ex_reg_data2 <= rf_read_data2;

                id_ex_imm6 <= id_imm6;
                id_ex_imm9 <= id_imm9;

                id_ex_branch_offset <= id_branch_offset;

                id_ex_jump_address <= id_jump_address;

                id_ex_reg_write <= id_reg_write;

                id_ex_alu_src_imm <= id_alu_src_imm;

                id_ex_mem_read <= id_mem_read;
                id_ex_mem_write <= id_mem_write;
                id_ex_mem_to_reg <= id_mem_to_reg;

                id_ex_branch <= id_branch;
                id_ex_jump <= id_jump;
                id_ex_halt <= id_halt;

                id_ex_alu_control <= id_alu_control;

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

        debug_ex_alu_result = ex_alu_result;

        debug_stall = stall;

        debug_flush = flush;

    end

endmodule