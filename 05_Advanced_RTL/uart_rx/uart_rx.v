module uart_rx #(
    parameter DATA_WIDTH = 8,
    parameter CLKS_PER_BIT = 16
)(
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  rx,

    output reg  [DATA_WIDTH-1:0] rx_data,
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
    reg [3:0]  bit_index;

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

            // data_valid is a one-clock pulse
            data_valid <= 1'b0;

            case (state)

                // ==========================================
                // IDLE
                // ==========================================

                IDLE: begin

                    busy         <= 1'b0;
                    baud_counter <= 0;
                    bit_index    <= 0;

                    // UART start bit is LOW
                    if (rx == 1'b0) begin

                        state        <= START;
                        busy         <= 1'b1;
                        baud_counter <= 0;

                    end

                end

                // ==========================================
                // START BIT
                // ==========================================

                START: begin

                    // Wait until the middle of the start bit
                    if (baud_counter == (CLKS_PER_BIT/2)-1) begin

                        baud_counter <= 0;

                        // Confirm that start bit is still LOW
                        if (rx == 1'b0) begin
                            state <= DATA;
                        end
                        else begin
                            // False start
                            state <= IDLE;
                            busy  <= 1'b0;
                        end

                    end
                    else begin

                        baud_counter <= baud_counter + 1'b1;

                    end

                end

                // ==========================================
                // DATA BITS
                // ==========================================

                DATA: begin

                    if (baud_counter == CLKS_PER_BIT-1) begin

                        baud_counter <= 0;

                        // Sample data bit
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

                // ==========================================
                // STOP BIT
                // ==========================================

                STOP: begin

                    if (baud_counter == CLKS_PER_BIT-1) begin

                        baud_counter <= 0;

                        // Stop bit should be HIGH
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