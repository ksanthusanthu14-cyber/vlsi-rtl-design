`timescale 1ns/1ps

module mini_risc_cpu_tb;

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

    logic clk;
    logic rst;

    logic [7:0]  imem_addr;
    logic [15:0] imem_instruction;

    logic        dmem_read;
    logic        dmem_write;
    logic [7:0]  dmem_addr;
    logic [7:0]  dmem_write_data;
    logic [7:0]  dmem_read_data;

    logic halted;

    logic [7:0] debug_pc;
    logic [7:0] debug_alu_result;

    logic [15:0] instruction_memory [0:255];
    logic [7:0]  data_memory [0:255];

    integer checks;
    integer passed;
    integer failed;
    integer i;


    // ============================================================
    // DUT
    // ============================================================

    mini_risc_cpu dut (
        .clk              (clk),
        .rst              (rst),

        .imem_addr        (imem_addr),
        .imem_instruction (imem_instruction),

        .dmem_read        (dmem_read),
        .dmem_write       (dmem_write),

        .dmem_addr        (dmem_addr),
        .dmem_write_data  (dmem_write_data),
        .dmem_read_data   (dmem_read_data),

        .halted           (halted),

        .debug_pc         (debug_pc),
        .debug_alu_result (debug_alu_result)
    );


    // ============================================================
    // INSTRUCTION MEMORY
    // ============================================================

    always_comb begin
        imem_instruction = instruction_memory[imem_addr];
    end


    // ============================================================
    // DATA MEMORY READ
    // ============================================================

    always_comb begin

        if (dmem_read)
            dmem_read_data = data_memory[dmem_addr];
        else
            dmem_read_data = 8'd0;

    end


    // ============================================================
    // DATA MEMORY WRITE
    // ============================================================

    always_ff @(posedge clk) begin

        if (dmem_write) begin

            data_memory[dmem_addr] <= dmem_write_data;

        end

    end


    // ============================================================
    // CLOCK
    // ============================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end


    // ============================================================
    // CHECK TASK
    // ============================================================

    task check;

        input condition;
        input [255:0] message;

        begin

            checks = checks + 1;

            if (condition) begin

                passed = passed + 1;

                $display("PASS: %s", message);

            end
            else begin

                failed = failed + 1;

                $display("FAIL: %s", message);

            end

        end

    endtask


    // ============================================================
    // R-TYPE ENCODER
    // ============================================================

    function [15:0] encode_r;

        input [3:0] opcode;
        input [2:0] rd;
        input [2:0] rs1;
        input [2:0] rs2;

        begin

            encode_r = {
                opcode,
                rd,
                rs1,
                rs2,
                3'b000
            };

        end

    endfunction


    // ============================================================
    // MOVI / LOAD ENCODER
    // ============================================================

    function [15:0] encode_imm9;

        input [3:0] opcode;
        input [2:0] rd;
        input [8:0] immediate;

        begin

            encode_imm9 = {
                opcode,
                rd,
                immediate
            };

        end

    endfunction


    // ============================================================
    // ADDI ENCODER
    // ============================================================

    function [15:0] encode_addi;

        input [2:0] rd;
        input [2:0] rs1;
        input [5:0] immediate;

        begin

            encode_addi = {
                OP_ADDI,
                rd,
                rs1,
                immediate
            };

        end

    endfunction


    // ============================================================
    // STORE ENCODER
    // ============================================================

    function [15:0] encode_store;

        input [2:0] rs1;
        input [8:0] address;

        begin

            encode_store = {
                OP_STORE,
                rs1,
                address
            };

        end

    endfunction


    // ============================================================
    // BRANCH ENCODER
    // ============================================================

    function [15:0] encode_branch;

        input [2:0] rs1;
        input [2:0] rs2;
        input [5:0] offset;

        begin

            encode_branch = {
                OP_BEQ,
                rs1,
                rs2,
                offset
            };

        end

    endfunction


    // ============================================================
    // JUMP ENCODER
    // ============================================================

    function [15:0] encode_jump;

        input [7:0] address;

        begin

            encode_jump = {
                OP_JMP,
                4'b0000,
                address
            };

        end

    endfunction


    // ============================================================
    // HALT ENCODER
    // ============================================================

    function [15:0] encode_halt;

        begin

            encode_halt = {
                OP_HALT,
                12'b0
            };

        end

    endfunction


    // ============================================================
    // CLEAR DATA MEMORY
    // ============================================================

    task clear_data_memory;

        integer j;

        begin

            for (j = 0; j < 256; j = j + 1)
                data_memory[j] = 8'd0;

        end

    endtask


    // ============================================================
    // RESET CPU
    // ============================================================

    task reset_cpu;

        begin

            @(negedge clk);

            rst = 1'b1;

            repeat (2)
                @(negedge clk);

            rst = 1'b0;

            @(negedge clk);

        end

    endtask


    // ============================================================
    // MAIN TEST
    // ============================================================

    initial begin

        checks = 0;
        passed = 0;
        failed = 0;

        rst = 1'b0;


        // ========================================================
        // INITIAL MEMORY
        // ========================================================

        for (i = 0; i < 256; i = i + 1) begin

            instruction_memory[i] = {OP_NOP, 12'b0};

            data_memory[i] = 8'd0;

        end


        $display("");
        $display("================================================");
        $display("          MINI RISC PROCESSOR TEST");
        $display("================================================");
        $display("");


        // ========================================================
        // TEST 1
        // ========================================================

        $display("TEST 1: BASIC ALU INSTRUCTIONS");


        instruction_memory[0] =
            encode_imm9(OP_MOVI, 3'd1, 9'd10);

        instruction_memory[1] =
            encode_imm9(OP_MOVI, 3'd2, 9'd20);

        instruction_memory[2] =
            encode_r(OP_ADD, 3'd3, 3'd1, 3'd2);

        instruction_memory[3] =
            encode_r(OP_SUB, 3'd4, 3'd3, 3'd1);

        instruction_memory[4] =
            encode_r(OP_AND, 3'd5, 3'd1, 3'd2);

        instruction_memory[5] =
            encode_r(OP_OR, 3'd6, 3'd1, 3'd2);

        instruction_memory[6] =
            encode_r(OP_XOR, 3'd7, 3'd1, 3'd2);

        instruction_memory[7] =
            encode_halt();


        reset_cpu();

        repeat (10)
            @(posedge clk);

        #1;


        check(
            dut.u_register_file.regs[1] == 8'd10,
            "R1 = 10"
        );

        check(
            dut.u_register_file.regs[2] == 8'd20,
            "R2 = 20"
        );

        check(
            dut.u_register_file.regs[3] == 8'd30,
            "R3 = R1 + R2 = 30"
        );

        check(
            dut.u_register_file.regs[4] == 8'd20,
            "R4 = R3 - R1 = 20"
        );

        check(
            dut.u_register_file.regs[5] == 8'd0,
            "R5 = R1 AND R2 = 0"
        );

        check(
            dut.u_register_file.regs[6] == 8'd30,
            "R6 = R1 OR R2 = 30"
        );

        check(
            dut.u_register_file.regs[7] == 8'd30,
            "R7 = R1 XOR R2 = 30"
        );

        check(
            halted == 1'b1,
            "CPU HALT asserted"
        );


        // ========================================================
        // TEST 2
        // ========================================================

        $display("");
        $display("TEST 2: ADDI");


        instruction_memory[0] =
            encode_imm9(OP_MOVI, 3'd1, 9'd5);

        instruction_memory[1] =
            encode_addi(3'd2, 3'd1, 6'd7);

        instruction_memory[2] =
            encode_r(OP_ADD, 3'd3, 3'd1, 3'd2);

        instruction_memory[3] =
            encode_halt();


        reset_cpu();

        repeat (7)
            @(posedge clk);

        #1;


        check(
            dut.u_register_file.regs[1] == 8'd5,
            "ADDI base register R1 = 5"
        );

        check(
            dut.u_register_file.regs[2] == 8'd12,
            "ADDI R2 = R1 + 7 = 12"
        );

        check(
            dut.u_register_file.regs[3] == 8'd17,
            "ADD R3 = R1 + R2 = 17"
        );


        // ========================================================
        // TEST 3 — STORE / LOAD
        // ========================================================

        $display("");
        $display("TEST 3: STORE AND LOAD");


        clear_data_memory();


        instruction_memory[0] =
            encode_imm9(OP_MOVI, 3'd1, 9'd42);

        instruction_memory[1] =
            encode_store(3'd1, 9'd20);

        instruction_memory[2] =
            encode_imm9(OP_LOAD, 3'd3, 9'd20);

        instruction_memory[3] =
            encode_halt();


        reset_cpu();


        // MOVI
        @(posedge clk);

        #1;


        // STORE
        @(posedge clk);

        #1;


        // Verify STORE immediately after its clock edge
        check(
            data_memory[20] == 8'd42,
            "STORE writes 42 to memory address 20"
        );


        // LOAD
        @(posedge clk);

        #1;


        // HALT
        @(posedge clk);

        #1;


        check(
            dut.u_register_file.regs[3] == 8'd42,
            "LOAD reads 42 into R3"
        );


        // ========================================================
        // TEST 4
        // ========================================================

        $display("");
        $display("TEST 4: REGISTER ZERO PROTECTION");


        instruction_memory[0] =
            encode_imm9(OP_MOVI, 3'd0, 9'd99);

        instruction_memory[1] =
            encode_imm9(OP_MOVI, 3'd1, 9'd10);

        instruction_memory[2] =
            encode_r(OP_ADD, 3'd2, 3'd0, 3'd1);

        instruction_memory[3] =
            encode_halt();


        reset_cpu();

        repeat (7)
            @(posedge clk);

        #1;


        check(
            dut.u_register_file.regs[0] == 8'd0,
            "R0 remains permanently zero"
        );

        check(
            dut.u_register_file.regs[2] == 8'd10,
            "ADD using R0 behaves correctly"
        );


        // ========================================================
        // TEST 5
        // ========================================================

        $display("");
        $display("TEST 5: BRANCH EQUAL");


        instruction_memory[0] =
            encode_imm9(OP_MOVI, 3'd1, 9'd5);

        instruction_memory[1] =
            encode_imm9(OP_MOVI, 3'd2, 9'd5);

        instruction_memory[2] =
            encode_branch(3'd1, 3'd2, 6'd2);

        instruction_memory[3] =
            encode_imm9(OP_MOVI, 3'd3, 9'd99);

        instruction_memory[4] =
            encode_imm9(OP_MOVI, 3'd3, 9'd55);

        instruction_memory[5] =
            encode_halt();


        reset_cpu();

        repeat (8)
            @(posedge clk);

        #1;


        check(
            dut.u_register_file.regs[3] == 8'd55,
            "Branch executes target when registers are equal"
        );


        // ========================================================
        // TEST 6
        // ========================================================

        $display("");
        $display("TEST 6: JUMP");


        instruction_memory[0] =
            encode_imm9(OP_MOVI, 3'd1, 9'd10);

        instruction_memory[1] =
            encode_jump(8'd3);

        instruction_memory[2] =
            encode_imm9(OP_MOVI, 3'd1, 9'd99);

        instruction_memory[3] =
            encode_imm9(OP_MOVI, 3'd2, 9'd77);

        instruction_memory[4] =
            encode_halt();


        reset_cpu();

        repeat (7)
            @(posedge clk);

        #1;


        check(
            dut.u_register_file.regs[1] == 8'd10,
            "JMP skips instruction at address 2"
        );

        check(
            dut.u_register_file.regs[2] == 8'd77,
            "JMP reaches target instruction"
        );


        // ========================================================
        // FINAL RESULT
        // ========================================================

        $display("");
        $display("================================================");
        $display("                 FINAL RESULT");
        $display("================================================");

        $display("TOTAL CHECKS  = %0d", checks);
        $display("PASSED CHECKS = %0d", passed);
        $display("FAILED CHECKS = %0d", failed);

        if (failed == 0)
            $display("OVERALL RESULT = PASS");
        else
            $display("OVERALL RESULT = FAIL");

        $display("================================================");

        $finish;

    end

endmodule