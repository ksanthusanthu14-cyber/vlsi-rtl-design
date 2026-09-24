`timescale 1ns/1ps

module lfsr_tb;

    localparam WIDTH = 4;
    localparam SEED  = 4'b0001;

    reg clk;
    reg rst;
    reg enable;

    wire [WIDTH-1:0] q;

    // ============================================================
    // DUT
    // ============================================================

    lfsr #(
        .WIDTH(WIDTH),
        .SEED(SEED)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .q(q)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    initial begin
        clk = 1'b0;

        forever #5 clk = ~clk;
    end

    // ============================================================
    // TEST VARIABLES
    // ============================================================

    integer i;
    integer unique_count;

    reg [15:0] seen;
    reg [3:0] expected;

    // ============================================================
    // TEST
    // ============================================================

    initial begin

        $dumpfile("lfsr.vcd");
        $dumpvars(0, lfsr_tb);

        // --------------------------------------------------------
        // Initial conditions
        // --------------------------------------------------------

        rst = 1'b1;
        enable = 1'b0;

        seen = 16'd0;
        unique_count = 0;

        // --------------------------------------------------------
        // TEST 1: RESET
        // --------------------------------------------------------

        #12;

        if (q === SEED) begin

            $display(
                "PASS: RESET -> Q = %b",
                q
            );

        end

        else begin

            $display(
                "FAIL: RESET -> Q = %b",
                q
            );

        end

        rst = 1'b0;
        enable = 1'b1;

        // --------------------------------------------------------
        // Initial expected state
        // --------------------------------------------------------

        expected = SEED;

        // --------------------------------------------------------
        // TEST 2: Generate 15 states
        //
        // Expected sequence:
        //
        // 0001
        // 0010
        // 0100
        // 1001
        // 0011
        // 0110
        // 1101
        // 1010
        // 0101
        // 1011
        // 0111
        // 1111
        // 1110
        // 1100
        // 1000
        // 0001
        // --------------------------------------------------------

        for (i = 0; i < 15; i = i + 1) begin

            @(posedge clk);
            #1;

            // Calculate expected next state

            expected = {
                expected[2:0],
                expected[3] ^ expected[2]
            };

            $display(
                "LFSR STEP %0d: Q = %b | EXPECTED = %b",
                i + 1,
                q,
                expected
            );

            // ----------------------------------------------------
            // Check actual state
            // ----------------------------------------------------

            if (q !== expected) begin

                $display(
                    "FAIL: LFSR MISMATCH AT STEP %0d",
                    i + 1
                );

            end

            // ----------------------------------------------------
            // Track unique states
            // ----------------------------------------------------

            if (!seen[q]) begin

                seen[q] = 1'b1;

                unique_count =
                    unique_count + 1;

            end

            // ----------------------------------------------------
            // Check zero lock-up
            // ----------------------------------------------------

            if (q === 4'b0000) begin

                $display(
                    "FAIL: ZERO STATE DETECTED"
                );

            end

        end

        // --------------------------------------------------------
        // TEST 3: 15 UNIQUE NON-ZERO STATES
        // --------------------------------------------------------

        if (unique_count === 15) begin

            $display(
                "PASS: 15 UNIQUE NON-ZERO STATES"
            );

        end

        else begin

            $display(
                "FAIL: UNIQUE STATES = %0d",
                unique_count
            );

        end

        // --------------------------------------------------------
        // TEST 4: SEED RETURN
        //
        // IMPORTANT:
        // The 15th shift has ALREADY returned the LFSR
        // to the seed. Therefore, do NOT clock again here.
        // --------------------------------------------------------

        if (q === SEED) begin

            $display(
                "PASS: LFSR RETURNED TO SEED = %b",
                q
            );

        end

        else begin

            $display(
                "FAIL: EXPECTED SEED = %b, GOT = %b",
                SEED,
                q
            );

        end

        // --------------------------------------------------------
        // TEST 5: ENABLE = 0 HOLD
        // --------------------------------------------------------

        enable = 1'b0;

        expected = q;

        repeat (3) begin

            @(posedge clk);
            #1;

        end

        if (q === expected) begin

            $display(
                "PASS: ENABLE=0 -> LFSR HOLDS STATE"
            );

        end

        else begin

            $display(
                "FAIL: LFSR DID NOT HOLD"
            );

        end

        // --------------------------------------------------------
        // COMPLETE
        // --------------------------------------------------------

        $display("");
        $display(
            "=============================================="
        );

        $display(
            "LFSR VERIFICATION COMPLETE"
        );

        $display(
            "=============================================="
        );

        $finish;

    end

endmodule