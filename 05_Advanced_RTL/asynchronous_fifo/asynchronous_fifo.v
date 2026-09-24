module asynchronous_fifo #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 3
)(
    // Write clock domain
    input  wire                  wr_clk,
    input  wire                  wr_rst,
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  full,

    // Read clock domain
    input  wire                  rd_clk,
    input  wire                  rd_rst,
    input  wire                  rd_en,
    output reg  [DATA_WIDTH-1:0] rd_data,
    output wire                  empty
);

    // FIFO memory
    localparam DEPTH = (1 << ADDR_WIDTH);

    reg [DATA_WIDTH-1:0] memory [0:DEPTH-1];

    // Binary pointers have one extra bit.
    reg [ADDR_WIDTH:0] wr_ptr_bin;
    reg [ADDR_WIDTH:0] rd_ptr_bin;

    // Gray-code pointers
    reg [ADDR_WIDTH:0] wr_ptr_gray;
    reg [ADDR_WIDTH:0] rd_ptr_gray;

    // Synchronized Gray pointers
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync1;
    reg [ADDR_WIDTH:0] rd_ptr_gray_sync2;

    reg [ADDR_WIDTH:0] wr_ptr_gray_sync1;
    reg [ADDR_WIDTH:0] wr_ptr_gray_sync2;

    // Next-state pointers
    reg [ADDR_WIDTH:0] wr_ptr_bin_next;
    reg [ADDR_WIDTH:0] wr_ptr_gray_next;

    reg [ADDR_WIDTH:0] rd_ptr_bin_next;
    reg [ADDR_WIDTH:0] rd_ptr_gray_next;

    // Status registers
    reg full_reg;
    reg empty_reg;

    assign full  = full_reg;
    assign empty = empty_reg;

    // ============================================================
    // WRITE POINTER
    // ============================================================

    always @(*) begin

        if (wr_en && !full_reg)
            wr_ptr_bin_next = wr_ptr_bin + 1'b1;
        else
            wr_ptr_bin_next = wr_ptr_bin;

        // Binary to Gray conversion
        wr_ptr_gray_next =
            (wr_ptr_bin_next >> 1) ^ wr_ptr_bin_next;

    end

    // ============================================================
    // READ POINTER
    // ============================================================

    always @(*) begin

        if (rd_en && !empty_reg)
            rd_ptr_bin_next = rd_ptr_bin + 1'b1;
        else
            rd_ptr_bin_next = rd_ptr_bin;

        // Binary to Gray conversion
        rd_ptr_gray_next =
            (rd_ptr_bin_next >> 1) ^ rd_ptr_bin_next;

    end

    // ============================================================
    // WRITE CLOCK DOMAIN
    // ============================================================

    always @(posedge wr_clk or posedge wr_rst) begin

        if (wr_rst) begin

            wr_ptr_bin  <= 0;
            wr_ptr_gray <= 0;
            full_reg    <= 1'b0;

        end
        else begin

            if (wr_en && !full_reg)
                memory[wr_ptr_bin[ADDR_WIDTH-1:0]] <= wr_data;

            wr_ptr_bin  <= wr_ptr_bin_next;
            wr_ptr_gray <= wr_ptr_gray_next;

            // Full detection
            full_reg <=
                (wr_ptr_gray_next ==
                {
                    ~rd_ptr_gray_sync2[ADDR_WIDTH:ADDR_WIDTH-1],
                    rd_ptr_gray_sync2[ADDR_WIDTH-2:0]
                });

        end

    end

    // ============================================================
    // READ CLOCK DOMAIN
    // ============================================================

    always @(posedge rd_clk or posedge rd_rst) begin

        if (rd_rst) begin

            rd_ptr_bin  <= 0;
            rd_ptr_gray <= 0;
            empty_reg   <= 1'b1;
            rd_data     <= 0;

        end
        else begin

            if (rd_en && !empty_reg)
                rd_data <= memory[rd_ptr_bin[ADDR_WIDTH-1:0]];

            rd_ptr_bin  <= rd_ptr_bin_next;
            rd_ptr_gray <= rd_ptr_gray_next;

            // Empty detection
            empty_reg <=
                (rd_ptr_gray_next == wr_ptr_gray_sync2);

        end

    end

    // ============================================================
    // SYNCHRONIZE READ POINTER INTO WRITE DOMAIN
    // ============================================================

    always @(posedge wr_clk or posedge wr_rst) begin

        if (wr_rst) begin

            rd_ptr_gray_sync1 <= 0;
            rd_ptr_gray_sync2 <= 0;

        end
        else begin

            rd_ptr_gray_sync1 <= rd_ptr_gray;
            rd_ptr_gray_sync2 <= rd_ptr_gray_sync1;

        end

    end

    // ============================================================
    // SYNCHRONIZE WRITE POINTER INTO READ DOMAIN
    // ============================================================

    always @(posedge rd_clk or posedge rd_rst) begin

        if (rd_rst) begin

            wr_ptr_gray_sync1 <= 0;
            wr_ptr_gray_sync2 <= 0;

        end
        else begin

            wr_ptr_gray_sync1 <= wr_ptr_gray;
            wr_ptr_gray_sync2 <= wr_ptr_gray_sync1;

        end

    end

endmodule