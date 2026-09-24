`timescale 1ns/1ps

module pipelined_risc_cpu (
    input  wire        clk,
    input  wire        rst,

    output reg [31:0] output_data,
    output reg        output_valid,
    output reg        halted
);

    // ============================================================
    // OPCODES
    // ============================================================

    localparam OP_NOP  = 6'd0;
    localparam OP_LDI  = 6'd1;
    localparam OP_ADD  = 6'd2;
    localparam OP_ADDI = 6'd3;
    localparam OP_SUB  = 6'd4;
    localparam OP_LD   = 6'd5;
    localparam OP_ST   = 6'd6;
    localparam OP_OUT  = 6'd7;
    localparam OP_HLT  = 6'd63;

    localparam ALU_ADD = 2'd0;
    localparam ALU_SUB = 2'd1;

    // ============================================================
    // PROGRAM COUNTER
    // ============================================================

    reg [31:0] pc;

    // ============================================================
    // REGISTER FILE
    // ============================================================

    reg [31:0] regs [0:31];

    // ============================================================
    // INSTRUCTION MEMORY
    // ============================================================

    reg [31:0] imem [0:255];

    // ============================================================
    // DATA MEMORY
    // ============================================================

    reg [31:0] dmem [0:255];

    // ============================================================
    // IF/ID PIPELINE REGISTER
    // ============================================================

    reg        ifid_valid;
    reg [31:0] ifid_pc;
    reg [31:0] ifid_instr;

    // ============================================================
    // ID/EX PIPELINE REGISTER
    // ============================================================

    reg        idex_valid;

    reg [31:0] idex_val1;
    reg [31:0] idex_val2;
    reg [31:0] idex_imm;

    reg [4:0]  idex_rs1;
    reg [4:0]  idex_rs2;
    reg [4:0]  idex_rd;

    reg [1:0]  idex_alu_op;

    reg        idex_use_imm;
    reg        idex_regwrite;
    reg        idex_memread;
    reg        idex_memwrite;
    reg        idex_outwrite;
    reg        idex_halt;

    // ============================================================
    // EX/MEM PIPELINE REGISTER
    // ============================================================

    reg        exmem_valid;

    reg [31:0] exmem_alu_result;
    reg [31:0] exmem_store_data;
    reg [31:0] exmem_out_data;

    reg [4:0]  exmem_rd;

    reg        exmem_regwrite;
    reg        exmem_memread;
    reg        exmem_memwrite;
    reg        exmem_outwrite;
    reg        exmem_halt;

    // ============================================================
    // MEM/WB PIPELINE REGISTER
    // ============================================================

    reg        memwb_valid;

    reg [31:0] memwb_wb_data;
    reg [31:0] memwb_out_data;

    reg [4:0]  memwb_rd;

    reg        memwb_regwrite;
    reg        memwb_outwrite;
    reg        memwb_halt;

    // ============================================================
    // DECODE SIGNALS
    // ============================================================

    reg [5:0] decode_opcode;

    reg [4:0] decode_rs1_idx;
    reg [4:0] decode_rs2_idx;
    reg [4:0] decode_rd_idx;

    reg [31:0] decode_val1;
    reg [31:0] decode_val2;
    reg [31:0] decode_imm;

    reg [1:0] decode_alu_op;

    reg decode_use_rs1;
    reg decode_use_rs2;

    reg decode_use_imm;
    reg decode_regwrite;
    reg decode_memread;
    reg decode_memwrite;
    reg decode_outwrite;
    reg decode_halt;

    // ============================================================
    // HAZARD DETECTION
    // ============================================================

    reg stall;

    always @(*) begin

        stall = 1'b0;

        if (idex_valid &&
            idex_memread &&
            (idex_rd != 5'd0)) begin

            if (decode_use_rs1 &&
                (decode_rs1_idx == idex_rd)) begin

                stall = 1'b1;
            end

            if (decode_use_rs2 &&
                (decode_rs2_idx == idex_rd)) begin

                stall = 1'b1;
            end
        end
    end

    // ============================================================
    // INSTRUCTION DECODE
    // ============================================================

    always @(*) begin

        decode_opcode = ifid_instr[31:26];

        decode_rs1_idx = ifid_instr[20:16];
        decode_rs2_idx = ifid_instr[15:11];
        decode_rd_idx  = ifid_instr[25:21];

        decode_val1 = 32'd0;
        decode_val2 = 32'd0;

        decode_imm = {{16{ifid_instr[15]}},
                      ifid_instr[15:0]};

        decode_alu_op = ALU_ADD;

        decode_use_rs1 = 1'b0;
        decode_use_rs2 = 1'b0;

        decode_use_imm = 1'b0;
        decode_regwrite = 1'b0;
        decode_memread = 1'b0;
        decode_memwrite = 1'b0;
        decode_outwrite = 1'b0;
        decode_halt = 1'b0;

        case (decode_opcode)

            // ----------------------------------------------------
            // LDI Rd, immediate
            // ----------------------------------------------------

            OP_LDI: begin

                decode_rd_idx = ifid_instr[25:21];

                decode_imm = {
                    16'd0,
                    ifid_instr[15:0]
                };

                decode_use_imm = 1'b1;
                decode_regwrite = 1'b1;
            end

            // ----------------------------------------------------
            // ADD Rd, Rs1, Rs2
            // ----------------------------------------------------

            OP_ADD: begin

                decode_use_rs1 = 1'b1;
                decode_use_rs2 = 1'b1;

                decode_regwrite = 1'b1;
            end

            // ----------------------------------------------------
            // ADDI Rd, Rs1, immediate
            // ----------------------------------------------------

            OP_ADDI: begin

                decode_use_rs1 = 1'b1;

                decode_use_imm = 1'b1;
                decode_regwrite = 1'b1;
            end

            // ----------------------------------------------------
            // SUB Rd, Rs1, Rs2
            // ----------------------------------------------------

            OP_SUB: begin

                decode_use_rs1 = 1'b1;
                decode_use_rs2 = 1'b1;

                decode_alu_op = ALU_SUB;
                decode_regwrite = 1'b1;
            end

            // ----------------------------------------------------
            // LD Rd, [Rs1 + immediate]
            // ----------------------------------------------------

            OP_LD: begin

                decode_use_rs1 = 1'b1;

                decode_use_imm = 1'b1;
                decode_memread = 1'b1;
                decode_regwrite = 1'b1;
            end

            // ----------------------------------------------------
            // ST Rs2, [Rs1 + immediate]
            //
            // For ST:
            // [25:21] = data register
            // [20:16] = base register
            // [15:0]  = offset
            // ----------------------------------------------------

            OP_ST: begin

                decode_rs2_idx = ifid_instr[25:21];

                decode_use_rs1 = 1'b1;
                decode_use_rs2 = 1'b1;

                decode_use_imm = 1'b1;
                decode_memwrite = 1'b1;

                decode_rd_idx = 5'd0;
            end

            // ----------------------------------------------------
            // OUT Rs1
            // ----------------------------------------------------

            OP_OUT: begin

                decode_use_rs1 = 1'b1;
                decode_outwrite = 1'b1;

                decode_rd_idx = 5'd0;
            end

            // ----------------------------------------------------
            // HLT
            // ----------------------------------------------------

            OP_HLT: begin

                decode_halt = 1'b1;
                decode_rd_idx = 5'd0;
            end

            default: begin
                // NOP
            end

        endcase

        // --------------------------------------------------------
        // Register file read
        // --------------------------------------------------------

        if (decode_rs1_idx == 5'd0)
            decode_val1 = 32'd0;
        else
            decode_val1 = regs[decode_rs1_idx];

        if (decode_rs2_idx == 5'd0)
            decode_val2 = 32'd0;
        else
            decode_val2 = regs[decode_rs2_idx];

        // --------------------------------------------------------
        // WB -> ID forwarding
        // --------------------------------------------------------

        if (memwb_regwrite &&
            (memwb_rd != 5'd0) &&
            decode_use_rs1 &&
            (decode_rs1_idx == memwb_rd)) begin

            decode_val1 = memwb_wb_data;
        end

        if (memwb_regwrite &&
            (memwb_rd != 5'd0) &&
            decode_use_rs2 &&
            (decode_rs2_idx == memwb_rd)) begin

            decode_val2 = memwb_wb_data;
        end

    end

    // ============================================================
    // EX STAGE FORWARDING
    // ============================================================

    reg [31:0] ex_operand1;
    reg [31:0] ex_operand2;

    always @(*) begin

        ex_operand1 = idex_val1;
        ex_operand2 = idex_val2;

        // --------------------------------------------------------
        // Forward from EX/MEM
        // Do NOT forward a load from EX/MEM because the loaded
        // data is not available until MEM/WB.
        // --------------------------------------------------------

        if (exmem_regwrite &&
            !exmem_memread &&
            (exmem_rd != 5'd0) &&
            (exmem_rd == idex_rs1)) begin

            ex_operand1 = exmem_alu_result;
        end

        else if (memwb_regwrite &&
                 (memwb_rd != 5'd0) &&
                 (memwb_rd == idex_rs1)) begin

            ex_operand1 = memwb_wb_data;
        end

        if (exmem_regwrite &&
            !exmem_memread &&
            (exmem_rd != 5'd0) &&
            (exmem_rd == idex_rs2)) begin

            ex_operand2 = exmem_alu_result;
        end

        else if (memwb_regwrite &&
                 (memwb_rd != 5'd0) &&
                 (memwb_rd == idex_rs2)) begin

            ex_operand2 = memwb_wb_data;
        end

    end

    // ============================================================
    // EX ALU
    // ============================================================

    reg [31:0] ex_alu_result;

    always @(*) begin

        if (idex_alu_op == ALU_SUB) begin

            ex_alu_result =
                ex_operand1 - ex_operand2;

        end

        else begin

            if (idex_use_imm)

                ex_alu_result =
                    ex_operand1 + idex_imm;

            else

                ex_alu_result =
                    ex_operand1 + ex_operand2;

        end
    end

    // ============================================================
    // MEMORY WRITEBACK DATA
    // ============================================================

    reg [31:0] memory_read_data;

    always @(*) begin

        memory_read_data =
            dmem[exmem_alu_result[7:0]];

    end

    // ============================================================
    // SEQUENTIAL PIPELINE
    // ============================================================

    integer i;

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            pc <= 32'd0;

            ifid_valid <= 1'b0;
            ifid_pc <= 32'd0;
            ifid_instr <= 32'd0;

            idex_valid <= 1'b0;
            idex_val1 <= 32'd0;
            idex_val2 <= 32'd0;
            idex_imm <= 32'd0;
            idex_rs1 <= 5'd0;
            idex_rs2 <= 5'd0;
            idex_rd <= 5'd0;

            idex_alu_op <= ALU_ADD;

            idex_use_imm <= 1'b0;
            idex_regwrite <= 1'b0;
            idex_memread <= 1'b0;
            idex_memwrite <= 1'b0;
            idex_outwrite <= 1'b0;
            idex_halt <= 1'b0;

            exmem_valid <= 1'b0;
            exmem_alu_result <= 32'd0;
            exmem_store_data <= 32'd0;
            exmem_out_data <= 32'd0;
            exmem_rd <= 5'd0;

            exmem_regwrite <= 1'b0;
            exmem_memread <= 1'b0;
            exmem_memwrite <= 1'b0;
            exmem_outwrite <= 1'b0;
            exmem_halt <= 1'b0;

            memwb_valid <= 1'b0;
            memwb_wb_data <= 32'd0;
            memwb_out_data <= 32'd0;
            memwb_rd <= 5'd0;

            memwb_regwrite <= 1'b0;
            memwb_outwrite <= 1'b0;
            memwb_halt <= 1'b0;

            output_data <= 32'd0;
            output_valid <= 1'b0;
            halted <= 1'b0;

            for (i = 0; i < 32; i = i + 1)
                regs[i] <= 32'd0;

            for (i = 0; i < 256; i = i + 1)
                dmem[i] <= 32'd0;

        end

        else begin

            // ----------------------------------------------------
            // Default output_valid is a one-cycle pulse
            // ----------------------------------------------------

            output_valid <= 1'b0;

            // ----------------------------------------------------
            // WRITEBACK STAGE
            // ----------------------------------------------------

            if (memwb_regwrite &&
                (memwb_rd != 5'd0)) begin

                regs[memwb_rd] <= memwb_wb_data;
            end

            // R0 is permanently zero
            regs[0] <= 32'd0;

            if (memwb_outwrite) begin

                output_data <= memwb_out_data;
                output_valid <= 1'b1;
            end

            if (memwb_halt) begin

                halted <= 1'b1;
            end

            // ----------------------------------------------------
            // MEMORY WRITE
            // ----------------------------------------------------

            if (exmem_memwrite) begin

                dmem[exmem_alu_result[7:0]]
                    <= exmem_store_data;
            end

            // ----------------------------------------------------
            // MEM/WB PIPELINE REGISTER
            // ----------------------------------------------------

            memwb_valid <= exmem_valid;

            if (exmem_memread)

                memwb_wb_data <= memory_read_data;

            else

                memwb_wb_data <= exmem_alu_result;

            memwb_out_data <= exmem_out_data;

            memwb_rd <= exmem_rd;

            memwb_regwrite <= exmem_regwrite;
            memwb_outwrite <= exmem_outwrite;
            memwb_halt <= exmem_halt;

            // ----------------------------------------------------
            // EX/MEM PIPELINE REGISTER
            // ----------------------------------------------------

            exmem_valid <= idex_valid;

            exmem_alu_result <= ex_alu_result;

            // Store data uses forwarded operand2
            exmem_store_data <= ex_operand2;

            // OUT uses forwarded operand1
            exmem_out_data <= ex_operand1;

            exmem_rd <= idex_rd;

            exmem_regwrite <= idex_regwrite;
            exmem_memread <= idex_memread;
            exmem_memwrite <= idex_memwrite;
            exmem_outwrite <= idex_outwrite;
            exmem_halt <= idex_halt;

            // ----------------------------------------------------
            // HALT CONDITION
            // ----------------------------------------------------

            if (!halted) begin

                // ------------------------------------------------
                // LOAD-USE HAZARD
                // ------------------------------------------------

                if (stall) begin

                    // Freeze PC
                    pc <= pc;

                    // Freeze IF/ID
                    ifid_valid <= ifid_valid;
                    ifid_pc <= ifid_pc;
                    ifid_instr <= ifid_instr;

                    // Insert bubble into ID/EX
                    idex_valid <= 1'b0;

                    idex_val1 <= 32'd0;
                    idex_val2 <= 32'd0;
                    idex_imm <= 32'd0;

                    idex_rs1 <= 5'd0;
                    idex_rs2 <= 5'd0;
                    idex_rd <= 5'd0;

                    idex_alu_op <= ALU_ADD;

                    idex_use_imm <= 1'b0;
                    idex_regwrite <= 1'b0;
                    idex_memread <= 1'b0;
                    idex_memwrite <= 1'b0;
                    idex_outwrite <= 1'b0;
                    idex_halt <= 1'b0;

                end

                else begin

                    // --------------------------------------------
                    // IF STAGE
                    // --------------------------------------------

                    ifid_valid <= 1'b1;
                    ifid_pc <= pc;
                    ifid_instr <= imem[pc[9:2]];

                    pc <= pc + 32'd4;

                    // --------------------------------------------
                    // ID -> EX
                    // --------------------------------------------

                    idex_valid <= ifid_valid;

                    idex_val1 <= decode_val1;
                    idex_val2 <= decode_val2;
                    idex_imm <= decode_imm;

                    idex_rs1 <= decode_rs1_idx;
                    idex_rs2 <= decode_rs2_idx;
                    idex_rd <= decode_rd_idx;

                    idex_alu_op <= decode_alu_op;

                    idex_use_imm <= decode_use_imm;
                    idex_regwrite <= decode_regwrite;
                    idex_memread <= decode_memread;
                    idex_memwrite <= decode_memwrite;
                    idex_outwrite <= decode_outwrite;
                    idex_halt <= decode_halt;

                end

            end

        end

    end

endmodule