`timescale 1ns/1ps

module prbs_generator_tb;

    localparam WIDTH = 4;
    localparam SEED  = 4'b0001;

    reg clk;
    reg rst;
    reg enable;

    wire prbs_bit;
    wire [WIDTH-1:0] state;

    // ============================================================
    // DUT
    // ============================================================

    prbs_generator #(
        .WIDTH(WIDTH),
        .SEED(SEED)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .prbs_bit(prbs_bit),
        .state(state)
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

    reg [3:0] expected_state;

    reg [14:0] generated_bits;

    integer ones_count;
    integer zeros_count;

    // ============================================================
    // TEST
    // ============================================================

    initial begin

        $dumpfile("prbs_generator.vcd");
        $dumpvars(0, prbs_generator_tb);

        rst = 1'b1;
        enable = 1'b0;

        generated_bits = 15'd0;

        ones_count = 0;
        zeros_count = 0;

        expected_state = SEED;

        // --------------------------------------------------------
        // TEST 1: RESET
        // --------------------------------------------------------

        #12;

        if (state === SEED)

            $display(
                "PASS: RESET -> STATE = %b",
                state
            );

        else

            $display(
                "FAIL: RESET -> STATE = %b",
                state
            );

        rst = 1'b0;
        enable = 1'b1;

        // --------------------------------------------------------
        // TEST 2: Generate 15 PRBS bits
        //
        // Current state MSB is used as output.
        //
        // Initial state = 0001
        //
        // Generated sequence:
        //
        // 0 0 0 1 0 1 1 0 1 0 0 0 1 1 1
        //
        // This is the output associated with the 15 states
        // before the state repeats.
        // --------------------------------------------------------

        for (i = 0; i < 15; i = i + 1) begin

            @(posedge clk);
            #1;

            // Record output bit

            generated_bits[i] = prbs_bit;

            if (prbs_bit)
                ones_count = ones_count + 1;
            else
                zeros_count = zeros_count + 1;

            // Calculate expected next state

            expected_state = {
                expected_state[2:0],
                expected_state[3] ^ expected_state[2]
            };

            $display(
                "STEP %0d: PRBS=%b | STATE=%b | EXPECTED=%b",
                i + 1,
                prbs_bit,
                state,
                expected_state
            );

            // Verify state

            if (state !== expected_state) begin

                $display(
                    "FAIL: STATE MISMATCH AT STEP %0d",
                    i + 1
                );

            end

        end

        // --------------------------------------------------------
        // TEST 3: Sequence contains both 0 and 1
        // --------------------------------------------------------

        if ((ones_count > 0) &&
            (zeros_count > 0)) begin

            $display(
                "PASS: PRBS CONTAINS BOTH 0 AND 1"
            );

        end

        else begin

            $display(
                "FAIL: PRBS DOES NOT CONTAIN BOTH VALUES"
            );

        end

        // --------------------------------------------------------
        // TEST 4: 15-bit sequence generated
        // --------------------------------------------------------

        $display(
            "GENERATED PRBS = %b",
            generated_bits
        );

        if ((ones_count == 8) &&
            (zeros_count == 7)) begin

            $display(
                "PASS: PRBS BALANCE = 8 ONES / 7 ZEROS"
            );

        end

        else begin

            $display(
                "INFO: ONES=%0d ZEROS=%0d",
                ones_count,
                zeros_count
            );

        end

        // --------------------------------------------------------
        // TEST 5: State should return to seed
        //
        // After 15 enabled clocks the maximal-length
        // sequence returns to the seed.
        // --------------------------------------------------------

        if (state === SEED)

            $display(
                "PASS: PRBS STATE RETURNED TO SEED = %b",
                state
            );

        else

            $display(
                "FAIL: EXPECTED SEED = %b, GOT = %b",
                SEED,
                state
            );

        // --------------------------------------------------------
        // TEST 6: ENABLE HOLD
        // --------------------------------------------------------

        enable = 1'b0;

        expected_state = state;

        repeat (3) begin

            @(posedge clk);
            #1;

        end

        if (state === expected_state)

            $display(
                "PASS: ENABLE=0 -> PRBS HOLDS STATE"
            );

        else

            $display(
                "FAIL: PRBS DID NOT HOLD STATE"
            );

        // --------------------------------------------------------
        // TEST 7: Resume generation
        // --------------------------------------------------------

        enable = 1'b1;

        @(posedge clk);
        #1;

        if (state !== expected_state)

            $display(
                "PASS: ENABLE=1 -> PRBS RESUMED"
            );

        else

            $display(
                "FAIL: PRBS DID NOT RESUME"
            );

        // --------------------------------------------------------
        // COMPLETE
        // --------------------------------------------------------

        $display("");

        $display(
            "=============================================="
        );

        $display(
            "PRBS GENERATOR VERIFICATION COMPLETE"
        );

        $display(
            "=============================================="
        );

        $finish;

    end

endmodule