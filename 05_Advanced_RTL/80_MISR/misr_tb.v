`timescale 1ns/1ps

module misr_tb;

    localparam WIDTH = 4;

    reg clk;
    reg rst;
    reg enable;

    reg [WIDTH-1:0] data_in;

    wire [WIDTH-1:0] signature;

    // ============================================================
    // DUT
    // ============================================================

    misr #(
        .WIDTH(WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .enable(enable),
        .data_in(data_in),
        .signature(signature)
    );

    // ============================================================
    // CLOCK
    // ============================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    // ============================================================
    // REFERENCE MODEL
    // ============================================================

    reg [WIDTH-1:0] expected_signature;

    reg feedback;

    // ============================================================
    // TEST VARIABLES
    // ============================================================

    integer i;

    reg [WIDTH-1:0] test_vectors [0:7];

    // ============================================================
    // TEST
    // ============================================================

    initial begin

        $dumpfile("misr.vcd");
        $dumpvars(0, misr_tb);

        // --------------------------------------------------------
        // Test vectors
        // --------------------------------------------------------

        test_vectors[0] = 4'b0001;
        test_vectors[1] = 4'b0010;
        test_vectors[2] = 4'b0100;
        test_vectors[3] = 4'b1000;
        test_vectors[4] = 4'b0011;
        test_vectors[5] = 4'b0110;
        test_vectors[6] = 4'b1010;
        test_vectors[7] = 4'b1111;

        // --------------------------------------------------------
        // Initial conditions
        // --------------------------------------------------------

        rst = 1'b1;
        enable = 1'b0;
        data_in = 4'b0000;

        expected_signature = 4'b0000;

        // --------------------------------------------------------
        // TEST 1: RESET
        // --------------------------------------------------------

        #12;

        if (signature === 4'b0000)

            $display(
                "PASS: RESET -> SIGNATURE = 0000"
            );

        else

            $display(
                "FAIL: RESET -> SIGNATURE = %b",
                signature
            );

        rst = 1'b0;
        enable = 1'b1;

        // --------------------------------------------------------
        // TEST 2: PROCESS RESPONSE VECTORS
        // --------------------------------------------------------

        for (i = 0; i < 8; i = i + 1) begin

            data_in = test_vectors[i];

            // ----------------------------------------------------
            // Reference MISR calculation
            // ----------------------------------------------------

            feedback =
                expected_signature[3] ^
                expected_signature[2] ^
                data_in[3];

            expected_signature =
                {
                    expected_signature[2:0],
                    feedback
                } ^ data_in;

            @(posedge clk);
            #1;

            $display(
                "STEP %0d: DATA=%b | SIGNATURE=%b | EXPECTED=%b",
                i + 1,
                data_in,
                signature,
                expected_signature
            );

            if (signature !== expected_signature) begin

                $display(
                    "FAIL: SIGNATURE MISMATCH AT STEP %0d",
                    i + 1
                );

            end

        end

        // --------------------------------------------------------
        // TEST 3: FINAL SIGNATURE
        // --------------------------------------------------------

        if (signature === expected_signature)

            $display(
                "PASS: FINAL SIGNATURE = %b",
                signature
            );

        else

            $display(
                "FAIL: FINAL SIGNATURE = %b",
                signature
            );

        // --------------------------------------------------------
        // TEST 4: ENABLE HOLD
        // --------------------------------------------------------

        enable = 1'b0;

        data_in = 4'b1010;

        @(posedge clk);
        #1;

        if (signature === expected_signature)

            $display(
                "PASS: ENABLE=0 -> SIGNATURE HOLDS"
            );

        else

            $display(
                "FAIL: MISR DID NOT HOLD"
            );

        // --------------------------------------------------------
        // TEST 5: RESUME
        // --------------------------------------------------------

        enable = 1'b1;

        feedback =
            expected_signature[3] ^
            expected_signature[2] ^
            data_in[3];

        expected_signature =
            {
                expected_signature[2:0],
                feedback
            } ^ data_in;

        @(posedge clk);
        #1;

        if (signature === expected_signature)

            $display(
                "PASS: ENABLE=1 -> MISR RESUMED"
            );

        else

            $display(
                "FAIL: MISR DID NOT RESUME"
            );

        // --------------------------------------------------------
        // COMPLETE
        // --------------------------------------------------------

        $display("");

        $display(
            "=============================================="
        );

        $display(
            "MISR VERIFICATION COMPLETE"
        );

        $display(
            "=============================================="
        );

        $finish;

    end

endmodule