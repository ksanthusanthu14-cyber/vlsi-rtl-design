`timescale 1ns/1ps

module advanced_vending_machine_tb;

    reg clk;
    reg rst;
    reg enable;

    reg [1:0] select_product;

    reg [7:0] coin_value;
    reg coin_insert;

    reg buy;
    reg cancel;

    wire dispense;
    wire [7:0] change;
    wire [7:0] balance;

    wire [3:0] state;

    wire [3:0] stock_available;

    wire insufficient_funds;
    wire out_of_stock;


    // =========================================================
    // DUT
    // =========================================================

    advanced_vending_machine dut (

        .clk(clk),
        .rst(rst),
        .enable(enable),

        .select_product(select_product),

        .coin_value(coin_value),
        .coin_insert(coin_insert),

        .buy(buy),
        .cancel(cancel),

        .dispense(dispense),

        .change(change),

        .balance(balance),

        .state(state),

        .stock_available(stock_available),

        .insufficient_funds(insufficient_funds),
        .out_of_stock(out_of_stock)
    );


    // =========================================================
    // CLOCK
    // =========================================================

    always #5 clk = ~clk;


    // =========================================================
    // STATE NAME
    // =========================================================

    function [127:0] state_name;

        input [3:0] state_value;

        begin

            case (state_value)

                4'd0: state_name = "IDLE";
                4'd1: state_name = "ACCEPTING";
                4'd2: state_name = "CHECK";
                4'd3: state_name = "DISPENSE";
                4'd4: state_name = "CHANGE";
                4'd5: state_name = "REFUND";
                4'd6: state_name = "ERROR";

                default:
                    state_name = "UNKNOWN";

            endcase

        end

    endfunction


    // =========================================================
    // MONITOR
    // =========================================================

    always @(posedge clk) begin

        #1;

        $display(
            "TIME=%0t | STATE=%s | PRODUCT=%0d | BALANCE=%0d | COIN=%b | BUY=%b | CANCEL=%b | DISPENSE=%b | CHANGE=%0d | STOCK=%b | INSUFFICIENT=%b | OUT_OF_STOCK=%b",
            $time,
            state_name(state),
            select_product,
            balance,
            coin_insert,
            buy,
            cancel,
            dispense,
            change,
            stock_available,
            insufficient_funds,
            out_of_stock
        );

    end


    // =========================================================
    // TEST
    // =========================================================

    initial begin

        $dumpfile("advanced_vending_machine.vcd");
        $dumpvars(0, advanced_vending_machine_tb);


        clk = 0;
        rst = 1;
        enable = 0;

        select_product = 0;

        coin_value = 0;
        coin_insert = 0;

        buy = 0;
        cancel = 0;


        // =====================================================
        // RESET
        // =====================================================

        #12;

        rst = 0;
        enable = 1;

        #1;

        if (state == 0 &&
            balance == 0 &&
            stock_available == 4'b1111) begin

            $display(
                "PASS: RESET | BALANCE=0 | ALL PRODUCTS IN STOCK"
            );

        end
        else begin

            $display("FAIL: RESET");
            $finish;

        end


        // =====================================================
        // TEST 1
        // PRODUCT 0 = 10
        // INSERT 10 AND BUY
        // =====================================================

        $display("");
        $display("========== TEST 1: PRODUCT 0 ==========");

        select_product = 2'd0;

        @(negedge clk);

        coin_value = 8'd10;
        coin_insert = 1;

        @(negedge clk);

        coin_insert = 0;
        coin_value = 0;

        #1;

        if (balance == 10)
            $display("PASS: BALANCE = 10");
        else begin
            $display("FAIL: BALANCE");
            $finish;
        end


        @(negedge clk);
        buy = 1;

        @(negedge clk);
        buy = 0;


        wait (state == 3);

        #1;

        if (dispense) begin
            $display("PASS: PRODUCT 0 DISPENSED");
        end
        else begin
            $display("FAIL: PRODUCT 0 NOT DISPENSED");
            $finish;
        end


        // =====================================================
        // TEST 2
        // PRODUCT 1 = 15
        // INSERT 20
        // EXPECT CHANGE = 5
        // =====================================================

        $display("");
        $display("========== TEST 2: PRODUCT 1 + CHANGE ==========");

        select_product = 2'd1;

        @(negedge clk);

        coin_value = 8'd20;
        coin_insert = 1;

        @(negedge clk);

        coin_insert = 0;
        coin_value = 0;

        @(negedge clk);

        buy = 1;

        @(negedge clk);

        buy = 0;


        wait (state == 3);

        #1;

        if (dispense) begin
            $display("PASS: PRODUCT 1 DISPENSED");
        end
        else begin
            $display("FAIL: PRODUCT 1 NOT DISPENSED");
            $finish;
        end


        wait (state == 4);

        #1;

        if (change == 5) begin

            $display(
                "PASS: CHANGE = 5"
            );

        end
        else begin

            $display(
                "FAIL: EXPECTED CHANGE = 5, GOT %0d",
                change
            );

            $finish;

        end


        // =====================================================
        // TEST 3
        // INSUFFICIENT FUNDS
        // PRODUCT 2 = 20
        // INSERT 10
        // =====================================================

        $display("");
        $display("========== TEST 3: INSUFFICIENT FUNDS ==========");

        select_product = 2'd2;

        @(negedge clk);

        coin_value = 8'd10;
        coin_insert = 1;

        @(negedge clk);

        coin_insert = 0;
        coin_value = 0;

        @(negedge clk);

        buy = 1;

        @(negedge clk);

        buy = 0;


        wait (state == 6);

        #1;

        if (insufficient_funds &&
            !dispense) begin

            $display(
                "PASS: INSUFFICIENT FUNDS DETECTED"
            );

        end
        else begin

            $display(
                "FAIL: INSUFFICIENT FUNDS"
            );

            $finish;

        end


        // =====================================================
        // TEST 4
        // CANCEL / REFUND
        // =====================================================

        $display("");
        $display("========== TEST 4: CANCEL / REFUND ==========");

        select_product = 2'd3;

        @(negedge clk);

        coin_value = 8'd15;
        coin_insert = 1;

        @(negedge clk);

        coin_insert = 0;
        coin_value = 0;


        @(negedge clk);

        cancel = 1;

        @(negedge clk);

        cancel = 0;


        wait (state == 5);

        #1;

        if (change == 15) begin

            $display(
                "PASS: REFUND = 15"
            );

        end
        else begin

            $display(
                "FAIL: EXPECTED REFUND = 15, GOT %0d",
                change
            );

            $finish;

        end


        // =====================================================
        // FINAL
        // =====================================================

        $display("");
        $display("==============================================");
        $display("ALL ADVANCED VENDING MACHINE TESTS PASSED");
        $display("==============================================");

        $finish;

    end

endmodule