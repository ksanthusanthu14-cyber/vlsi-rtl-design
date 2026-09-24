module uart_tx #(
    parameter DATA_WIDTH = 8,
    parameter CLKS_PER_BIT = 16
)(
    input  wire                  clk,
    input  wire                  rst,

    input  wire                  tx_start,
    input  wire [DATA_WIDTH-1:0] tx_data,

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

                // ==========================================
                // IDLE
                // ==========================================

                IDLE: begin

                    tx           <= 1'b1;
                    busy         <= 1'b0;
                    baud_counter <= 0;
                    bit_index    <= 0;

                    if (tx_start) begin

                        data_reg <= tx_data;

                        state <= START;
                        busy  <= 1'b1;

                    end

                end

                // ==========================================
                // START BIT
                // ==========================================

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

                // ==========================================
                // DATA BITS
                // ==========================================

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

                // ==========================================
                // STOP BIT
                // ==========================================

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

                    state        <= IDLE;
                    tx           <= 1'b1;
                    busy         <= 1'b0;
                    baud_counter <= 0;
                    bit_index    <= 0;

                end

            endcase

        end

    end

endmodule