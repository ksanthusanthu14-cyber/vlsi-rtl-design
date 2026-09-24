`timescale 1ns/1ps

module advanced_vending_machine #(
    parameter BALANCE_WIDTH = 8,
    parameter STOCK_WIDTH   = 4
)(
    input wire clk,
    input wire rst,
    input wire enable,

    input wire [1:0] select_product,

    input wire [7:0] coin_value,
    input wire coin_insert,

    input wire buy,
    input wire cancel,

    output reg dispense,
    output reg [7:0] change,
    output reg [7:0] balance,

    output reg [3:0] state,

    output reg [3:0] stock_available,

    output reg insufficient_funds,
    output reg out_of_stock
);

    // =========================================================
    // PRODUCT PRICES
    // =========================================================

    localparam PRICE_0 = 8'd10;
    localparam PRICE_1 = 8'd15;
    localparam PRICE_2 = 8'd20;
    localparam PRICE_3 = 8'd25;


    // =========================================================
    // FSM STATES
    // =========================================================

    localparam STATE_IDLE       = 4'd0;
    localparam STATE_ACCEPTING  = 4'd1;
    localparam STATE_CHECK      = 4'd2;
    localparam STATE_DISPENSE   = 4'd3;
    localparam STATE_CHANGE     = 4'd4;
    localparam STATE_REFUND     = 4'd5;
    localparam STATE_ERROR      = 4'd6;


    reg [3:0] next_state;

    reg [7:0] selected_price;

    reg [7:0] change_reg;

    reg [3:0] stock [0:3];


    // =========================================================
    // SELECTED PRODUCT PRICE
    // =========================================================

    always @(*) begin

        case (select_product)

            2'd0:
                selected_price = PRICE_0;

            2'd1:
                selected_price = PRICE_1;

            2'd2:
                selected_price = PRICE_2;

            2'd3:
                selected_price = PRICE_3;

            default:
                selected_price = PRICE_0;

        endcase

    end


    // =========================================================
    // STOCK REGISTER
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            stock[0] <= 4'd5;
            stock[1] <= 4'd5;
            stock[2] <= 4'd5;
            stock[3] <= 4'd5;

        end

        else if (!enable) begin

            stock[0] <= 4'd5;
            stock[1] <= 4'd5;
            stock[2] <= 4'd5;
            stock[3] <= 4'd5;

        end

        else begin

            if (state == STATE_DISPENSE) begin

                case (select_product)

                    2'd0:
                        if (stock[0] != 0)
                            stock[0] <= stock[0] - 1'b1;

                    2'd1:
                        if (stock[1] != 0)
                            stock[1] <= stock[1] - 1'b1;

                    2'd2:
                        if (stock[2] != 0)
                            stock[2] <= stock[2] - 1'b1;

                    2'd3:
                        if (stock[3] != 0)
                            stock[3] <= stock[3] - 1'b1;

                    default:
                        ;

                endcase

            end

        end

    end


    // =========================================================
    // STOCK AVAILABILITY
    // =========================================================

    always @(*) begin

        stock_available[0] = (stock[0] != 0);
        stock_available[1] = (stock[1] != 0);
        stock_available[2] = (stock[2] != 0);
        stock_available[3] = (stock[3] != 0);

    end


    // =========================================================
    // BALANCE REGISTER
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            balance <= 8'd0;

        end

        else if (!enable) begin

            balance <= 8'd0;

        end

        else begin

            // -------------------------------------------------
            // ERROR STATE
            // Clear failed transaction.
            //
            // If a new coin arrives during ERROR, treat it as
            // the first coin of the next transaction.
            // -------------------------------------------------

            if (state == STATE_ERROR) begin

                if (coin_insert)
                    balance <= coin_value;
                else
                    balance <= 8'd0;

            end

            // -------------------------------------------------
            // CHANGE RETURNED
            // -------------------------------------------------

            else if (state == STATE_CHANGE) begin

                balance <= 8'd0;

            end

            // -------------------------------------------------
            // REFUND RETURNED
            // -------------------------------------------------

            else if (state == STATE_REFUND) begin

                balance <= 8'd0;

            end

            // -------------------------------------------------
            // SUCCESSFUL PURCHASE
            // -------------------------------------------------

            else if (state == STATE_CHECK) begin

                if (balance >= selected_price)
                    balance <= balance - selected_price;

            end

            // -------------------------------------------------
            // NORMAL COIN INSERTION
            // -------------------------------------------------

            else if (coin_insert) begin

                balance <= balance + coin_value;

            end

        end

    end


    // =========================================================
    // CHANGE / REFUND REGISTER
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            change_reg <= 8'd0;

        end

        else if (!enable) begin

            change_reg <= 8'd0;

        end

        else begin

            // -------------------------------------------------
            // PURCHASE CHANGE
            // -------------------------------------------------

            if (state == STATE_CHECK) begin

                if (balance >= selected_price)
                    change_reg <= balance - selected_price;
                else
                    change_reg <= 8'd0;

            end

            // -------------------------------------------------
            // REFUND
            // Capture current balance when CANCEL is active.
            // -------------------------------------------------

            else if (
                (state == STATE_IDLE ||
                 state == STATE_ACCEPTING)
                && cancel
            ) begin

                change_reg <= balance;

            end

            // -------------------------------------------------
            // CLEAR AFTER CHANGE
            // -------------------------------------------------

            else if (state == STATE_CHANGE) begin

                change_reg <= 8'd0;

            end

            // -------------------------------------------------
            // CLEAR AFTER REFUND
            // -------------------------------------------------

            else if (state == STATE_REFUND) begin

                change_reg <= 8'd0;

            end

        end

    end


    // =========================================================
    // CHANGE OUTPUT
    // =========================================================

    always @(*) begin

        change = change_reg;

    end


    // =========================================================
    // NEXT STATE LOGIC
    // =========================================================

    always @(*) begin

        next_state = state;

        case (state)

            // =================================================
            // IDLE
            // =================================================

            STATE_IDLE: begin

                if (coin_insert)

                    next_state = STATE_ACCEPTING;

                else if (buy)

                    next_state = STATE_CHECK;

                else if (cancel)

                    next_state = STATE_REFUND;

            end


            // =================================================
            // ACCEPTING
            // =================================================

            STATE_ACCEPTING: begin

                if (cancel)

                    next_state = STATE_REFUND;

                else if (buy)

                    next_state = STATE_CHECK;

                else

                    next_state = STATE_ACCEPTING;

            end


            // =================================================
            // CHECK
            // =================================================

            STATE_CHECK: begin

                case (select_product)

                    2'd0: begin

                        if (stock[0] == 0)

                            next_state = STATE_ERROR;

                        else if (balance < PRICE_0)

                            next_state = STATE_ERROR;

                        else

                            next_state = STATE_DISPENSE;

                    end


                    2'd1: begin

                        if (stock[1] == 0)

                            next_state = STATE_ERROR;

                        else if (balance < PRICE_1)

                            next_state = STATE_ERROR;

                        else

                            next_state = STATE_DISPENSE;

                    end


                    2'd2: begin

                        if (stock[2] == 0)

                            next_state = STATE_ERROR;

                        else if (balance < PRICE_2)

                            next_state = STATE_ERROR;

                        else

                            next_state = STATE_DISPENSE;

                    end


                    2'd3: begin

                        if (stock[3] == 0)

                            next_state = STATE_ERROR;

                        else if (balance < PRICE_3)

                            next_state = STATE_ERROR;

                        else

                            next_state = STATE_DISPENSE;

                    end


                    default: begin

                        next_state = STATE_ERROR;

                    end

                endcase

            end


            // =================================================
            // DISPENSE
            // =================================================

            STATE_DISPENSE: begin

                if (change_reg != 0)

                    next_state = STATE_CHANGE;

                else

                    next_state = STATE_IDLE;

            end


            // =================================================
            // CHANGE
            // =================================================

            STATE_CHANGE: begin

                next_state = STATE_IDLE;

            end


            // =================================================
            // REFUND
            // =================================================

            STATE_REFUND: begin

                next_state = STATE_IDLE;

            end


            // =================================================
            // ERROR
            // =================================================

            STATE_ERROR: begin

                next_state = STATE_IDLE;

            end


            // =================================================
            // DEFAULT
            // =================================================

            default: begin

                next_state = STATE_IDLE;

            end

        endcase

    end


    // =========================================================
    // STATE REGISTER
    // =========================================================

    always @(posedge clk or posedge rst) begin

        if (rst)

            state <= STATE_IDLE;

        else if (!enable)

            state <= STATE_IDLE;

        else

            state <= next_state;

    end


    // =========================================================
    // OUTPUT LOGIC
    // =========================================================

    always @(*) begin

        dispense = 1'b0;

        insufficient_funds = 1'b0;

        out_of_stock = 1'b0;


        case (state)

            // -------------------------------------------------
            // DISPENSE
            // -------------------------------------------------

            STATE_DISPENSE: begin

                dispense = 1'b1;

            end


            // -------------------------------------------------
            // ERROR
            // -------------------------------------------------

            STATE_ERROR: begin

                case (select_product)

                    2'd0: begin

                        if (stock[0] == 0)

                            out_of_stock = 1'b1;

                        else

                            insufficient_funds = 1'b1;

                    end


                    2'd1: begin

                        if (stock[1] == 0)

                            out_of_stock = 1'b1;

                        else

                            insufficient_funds = 1'b1;

                    end


                    2'd2: begin

                        if (stock[2] == 0)

                            out_of_stock = 1'b1;

                        else

                            insufficient_funds = 1'b1;

                    end


                    2'd3: begin

                        if (stock[3] == 0)

                            out_of_stock = 1'b1;

                        else

                            insufficient_funds = 1'b1;

                    end


                    default: begin

                        insufficient_funds = 1'b1;

                    end

                endcase

            end

        endcase

    end

endmodule