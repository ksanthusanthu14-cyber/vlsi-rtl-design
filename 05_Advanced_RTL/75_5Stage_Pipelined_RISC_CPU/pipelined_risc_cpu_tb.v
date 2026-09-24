`timescale 1ns/1ps

module pipelined_risc_cpu_tb;

    reg clk;
    reg rst;

    wire [31:0] output_data;
    wire        output_valid;
    wire        halted;

    // ============================================================
    // DUT
    // ============================================================

    pipelined_risc_cpu dut (
        .clk(clk),
        .rst(rst),
        .output_data(output_data),
        .output_valid(output_valid),
        .halted(halted)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ============================================================
    // INSTRUCTION ENCODERS
    // ============================================================

    function [31:0] enc_ldi;

        input [4:0] rd;
        input [15:0] imm;

        begin
            enc_ldi = {
                6'd1,
                rd,
                5'd0,
                imm
            };
        end

    endfunction

    function [31:0] enc_add;

        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;

        begin
            enc_add = {
                6'd2,
                rd,
                rs1,
                rs2,
                11'd0
            };
        end

    endfunction

    function [31:0] enc_addi;

        input [4:0] rd;
        input [4:0] rs1;
        input [15:0] imm;

        begin
            enc_addi = {
                6'd3,
                rd,
                rs1,
                imm
            };
        end

    endfunction

    function [31:0] enc_sub;

        input [4:0] rd;
        input [4:0] rs1;
        input [4:0] rs2;

        begin
            enc_sub = {
                6'd4,
                rd,
                rs1,
                rs2,
                11'd0
            };
        end

    endfunction

    function [31:0] enc_ld;

        input [4:0] rd;
        input [4:0] base;
        input [15:0] imm;

        begin
            enc_ld = {
                6'd5,
                rd,
                base,
                imm
            };
        end

    endfunction

    function [31:0] enc_st;

        input [4:0] data_reg;
        input [4:0] base;
        input [15:0] imm;

        begin
            enc_st = {
                6'd6,
                data_reg,
                base,
                imm
            };
        end

    endfunction

    function [31:0] enc_out;

        input [4:0] rs;

        begin
            enc_out = {
                6'd7,
                5'd0,
                rs,
                16'd0
            };
        end

    endfunction

    function [31:0] enc_hlt;

        begin
            enc_hlt = {
                6'd63,
                26'd0
            };
        end

    endfunction

    // ============================================================
    // CAPTURE OUTPUT
    // ============================================================

    reg [31:0] last_output;

    always @(posedge clk) begin

        if (output_valid) begin

            last_output <= output_data;

            $display(
                "OUTPUT: %0d",
                output_data
            );

        end

    end

    // ============================================================
    // TEST
    // ============================================================

    integer i;

    initial begin

        $dumpfile("pipelined_risc_cpu.vcd");
        $dumpvars(0, pipelined_risc_cpu_tb);

        // --------------------------------------------------------
        // Initialize memories
        // --------------------------------------------------------

        for (i = 0; i < 256; i = i + 1) begin

            dut.imem[i] = 32'd0;
            dut.dmem[i] = 32'd0;

        end

        // --------------------------------------------------------
        // PROGRAM
        //
        // R1 = 10
        // R2 = 5
        // R3 = R1 + R2 = 15
        // R4 = R3 + 3 = 18
        // MEM[1] = R4 = 18
        // R5 = MEM[1] = 18
        // R6 = R5 + R2 = 23
        // R7 = R6 + R4 = 41
        // OUT R7
        // HLT
        // --------------------------------------------------------

        dut.imem[0] = enc_ldi(
            5'd1,
            16'd10
        );

        dut.imem[1] = enc_ldi(
            5'd2,
            16'd5
        );

        dut.imem[2] = enc_add(
            5'd3,
            5'd1,
            5'd2
        );

        dut.imem[3] = enc_addi(
            5'd4,
            5'd3,
            16'd3
        );

        dut.imem[4] = enc_st(
            5'd4,
            5'd0,
            16'd1
        );

        dut.imem[5] = enc_ld(
            5'd5,
            5'd0,
            16'd1
        );

        // Load-use hazard:
        // R5 is loaded immediately before this ADD.

        dut.imem[6] = enc_add(
            5'd6,
            5'd5,
            5'd2
        );

        // Forwarding test

        dut.imem[7] = enc_add(
            5'd7,
            5'd6,
            5'd4
        );

        dut.imem[8] = enc_out(
            5'd7
        );

        dut.imem[9] = enc_hlt();

        // --------------------------------------------------------
        // Reset
        // --------------------------------------------------------

        rst = 1'b1;

        #20;

        rst = 1'b0;

        // --------------------------------------------------------
        // Run
        // --------------------------------------------------------

        repeat (60)
            @(posedge clk);

        #2;

        $display("");
        $display("==============================================");
        $display("5-STAGE PIPELINED RISC CPU VERIFICATION");
        $display("==============================================");

        // --------------------------------------------------------
        // CHECK REGISTERS
        // --------------------------------------------------------

        if (dut.regs[1] === 32'd10)
            $display("PASS: R1 = 10");
        else
            $display(
                "FAIL: R1 = %0d",
                dut.regs[1]
            );

        if (dut.regs[2] === 32'd5)
            $display("PASS: R2 = 5");
        else
            $display(
                "FAIL: R2 = %0d",
                dut.regs[2]
            );

        if (dut.regs[3] === 32'd15)
            $display("PASS: R3 = 15");
        else
            $display(
                "FAIL: R3 = %0d",
                dut.regs[3]
            );

        if (dut.regs[4] === 32'd18)
            $display("PASS: R4 = 18");
        else
            $display(
                "FAIL: R4 = %0d",
                dut.regs[4]
            );

        if (dut.regs[5] === 32'd18)
            $display("PASS: R5 = 18");
        else
            $display(
                "FAIL: R5 = %0d",
                dut.regs[5]
            );

        if (dut.regs[6] === 32'd23)
            $display("PASS: R6 = 23");
        else
            $display(
                "FAIL: R6 = %0d",
                dut.regs[6]
            );

        if (dut.regs[7] === 32'd41)
            $display("PASS: R7 = 41");
        else
            $display(
                "FAIL: R7 = %0d",
                dut.regs[7]
            );

        // --------------------------------------------------------
        // CHECK MEMORY
        // --------------------------------------------------------

        if (dut.dmem[1] === 32'd18)
            $display("PASS: MEM[1] = 18");
        else
            $display(
                "FAIL: MEM[1] = %0d",
                dut.dmem[1]
            );

        // --------------------------------------------------------
        // CHECK OUTPUT
        // --------------------------------------------------------

        if (last_output === 32'd41)
            $display("PASS: OUTPUT = 41");
        else
            $display(
                "FAIL: OUTPUT = %0d",
                last_output
            );

        // --------------------------------------------------------
        // CHECK HALT
        // --------------------------------------------------------

        if (halted)
            $display("PASS: CPU HALTED");
        else
            $display("FAIL: CPU DID NOT HALT");

        $display("==============================================");

        $finish;

    end

endmodule