module complete_uart #(
    parameter DATA_WIDTH = 8,
    parameter CLKS_PER_BIT = 16
)(
    input  wire                  clk,
    input  wire                  rst,

    // Transmitter interface
    input  wire                  tx_start,
    input  wire [DATA_WIDTH-1:0] tx_data,

    output wire                  tx,
    output wire                  tx_busy,
    output wire                  tx_done,

    // Receiver interface
    output wire [DATA_WIDTH-1:0] rx_data,
    output wire                  rx_valid,
    output wire                  rx_busy
);

    // ---------------------------------------------------------
    // UART TX
    // ---------------------------------------------------------

    uart_tx #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) tx_inst (
        .clk(clk),
        .rst(rst),
        .tx_start(tx_start),
        .tx_data(tx_data),
        .tx(tx),
        .busy(tx_busy),
        .done(tx_done)
    );

    // ---------------------------------------------------------
    // UART RX
    // ---------------------------------------------------------

    uart_rx #(
        .DATA_WIDTH(DATA_WIDTH),
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) rx_inst (
        .clk(clk),
        .rst(rst),
        .rx(tx),
        .rx_data(rx_data),
        .data_valid(rx_valid),
        .busy(rx_busy)
    );

endmodule


// ============================================================
// UART TRANSMITTER
// ============================================================

module uart_tx #(
    parameter DATA_WIDTH = 8,
    parameter CLKS_PER_BIT = 16
)(
    input wire                   clk,
    input wire                   rst,

    input wire                   tx_start,
    input wire [DATA_WIDTH-1:0]  tx_data,

    output reg                   tx,
    output reg                   busy,
    output reg                   done
);

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    reg [2:0] state;

    reg [DATA_WIDTH-1:0] data_reg;

    reg [31:0] baud_counter;
    reg [3:0]  bit_index;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            state        <= IDLE;
            tx           <= 1'b1;
            busy         <= 1'b0;
            done         <= 1'b0;
            data_reg     <= 0;
            baud_counter <= 0;
            bit_index    <= 0;
        end

        else begin

            done <= 1'b0;

            case (state)

                IDLE: begin

                    tx           <= 1'b1;
                    busy         <= 1'b0;
                    baud_counter <= 0;
                    bit_index    <= 0;

                    if (tx_start) begin
                        data_reg <= tx_data;
                        state    <= START;
                        busy     <= 1'b1;
                    end

                end

                START: begin

                    tx <= 1'b0;

                    if (baud_counter == CLKS_PER_BIT - 1) begin
                        baud_counter <= 0;
                        state <= DATA;
                    end
                    else begin
                        baud_counter <= baud_counter + 1'b1;
                    end

                end

                DATA: begin

                    tx <= data_reg[bit_index];

                    if (baud_counter == CLKS_PER_BIT - 1) begin

                        baud_counter <= 0;

                        if (bit_index == DATA_WIDTH - 1) begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end

                    end
                    else begin
                        baud_counter <= baud_counter + 1'b1;
                    end

                end

                STOP: begin

                    tx <= 1'b1;

                    if (baud_counter == CLKS_PER_BIT - 1) begin
                        baud_counter <= 0;
                        state <= IDLE;
                        busy <= 1'b0;
                        done <= 1'b1;
                    end
                    else begin
                        baud_counter <= baud_counter + 1'b1;
                    end

                end

                default: begin
                    state <= IDLE;
                    tx <= 1'b1;
                    busy <= 1'b0;
                    baud_counter <= 0;
                    bit_index <= 0;
                end

            endcase
        end
    end

endmodule


// ============================================================
// UART RECEIVER
// ============================================================

module uart_rx #(
    parameter DATA_WIDTH = 8,
    parameter CLKS_PER_BIT = 16
)(
    input wire                   clk,
    input wire                   rst,

    input wire                   rx,

    output reg [DATA_WIDTH-1:0]  rx_data,
    output reg                   data_valid,
    output reg                   busy
);

    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;

    reg [2:0] state;

    reg [DATA_WIDTH-1:0] data_reg;

    reg [31:0] baud_counter;
    reg [3:0] bit_index;

    always @(posedge clk or posedge rst) begin

        if (rst) begin
            state        <= IDLE;
            rx_data      <= 0;
            data_valid   <= 1'b0;
            busy         <= 1'b0;
            data_reg     <= 0;
            baud_counter <= 0;
            bit_index    <= 0;
        end

        else begin

            data_valid <= 1'b0;

            case (state)

                IDLE: begin

                    busy         <= 1'b0;
                    baud_counter <= 0;
                    bit_index    <= 0;

                    if (rx == 1'b0) begin
                        state        <= START;
                        busy         <= 1'b1;
                        baud_counter <= 0;
                    end

                end

                START: begin

                    if (baud_counter == (CLKS_PER_BIT/2)-1) begin

                        baud_counter <= 0;

                        if (rx == 1'b0) begin
                            state <= DATA;
                        end
                        else begin
                            state <= IDLE;
                            busy  <= 1'b0;
                        end

                    end
                    else begin
                        baud_counter <= baud_counter + 1'b1;
                    end

                end

                DATA: begin

                    if (baud_counter == CLKS_PER_BIT-1) begin

                        baud_counter <= 0;

                        data_reg[bit_index] <= rx;

                        if (bit_index == DATA_WIDTH-1) begin
                            bit_index <= 0;
                            state <= STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end

                    end
                    else begin
                        baud_counter <= baud_counter + 1'b1;
                    end

                end

                STOP: begin

                    if (baud_counter == CLKS_PER_BIT-1) begin

                        baud_counter <= 0;

                        if (rx == 1'b1) begin
                            rx_data    <= data_reg;
                            data_valid <= 1'b1;
                        end

                        state <= IDLE;
                        busy  <= 1'b0;

                    end
                    else begin
                        baud_counter <= baud_counter + 1'b1;
                    end

                end

                default: begin
                    state        <= IDLE;
                    rx_data      <= 0;
                    data_valid   <= 1'b0;
                    busy         <= 1'b0;
                    baud_counter <= 0;
                    bit_index    <= 0;
                end

            endcase

        end

    end

endmodule