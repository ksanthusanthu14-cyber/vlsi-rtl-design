`timescale 1ns/1ps

module sync_fifo_tb;

    parameter DATA_WIDTH = 8;
    parameter DEPTH      = 16;

    reg clk;
    reg rst;

    reg wr_en;
    reg rd_en;

    reg [DATA_WIDTH-1:0] din;
    wire [DATA_WIDTH-1:0] dout;

    wire full;
    wire empty;

    // DUT
    sync_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(DEPTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din(din),
        .dout(dout),
        .full(full),
        .empty(empty)
    );

    // Clock generation
    always #5 clk = ~clk;

    // Waveform
    initial begin
        $dumpfile("sync_fifo.vcd");
        $dumpvars(0, sync_fifo_tb);
    end

    // Display
    initial begin
        $monitor(
            "TIME=%0t | RST=%b | WR=%b | RD=%b | DIN=%h | DOUT=%h | FULL=%b | EMPTY=%b",
            $time,
            rst,
            wr_en,
            rd_en,
            din,
            dout,
            full,
            empty
        );
    end

    initial begin

        // Initial values
        clk   = 0;
        rst   = 1;
        wr_en = 0;
        rd_en = 0;
        din   = 0;

        // Reset
        #12;

        rst = 0;

        // -----------------------------
        // WRITE DATA
        // -----------------------------

        @(posedge clk);
        #1;

        wr_en = 1;
        din = 8'hA1;

        @(posedge clk);
        #1;

        din = 8'hB2;

        @(posedge clk);
        #1;

        din = 8'hC3;

        @(posedge clk);
        #1;

        wr_en = 0;

        // -----------------------------
        // READ DATA
        // -----------------------------

        rd_en = 1;

        @(posedge clk);
        #1;

        @(posedge clk);
        #1;

        @(posedge clk);
        #1;

        rd_en = 0;

        // -----------------------------
        // WRITE MORE DATA
        // -----------------------------

        wr_en = 1;
        din = 8'h11;

        @(posedge clk);
        #1;

        din = 8'h22;

        @(posedge clk);
        #1;

        din = 8'h33;

        @(posedge clk);
        #1;

        wr_en = 0;

        // -----------------------------
        // READ AGAIN
        // -----------------------------

        rd_en = 1;

        repeat (3) begin
            @(posedge clk);
            #1;
        end

        rd_en = 0;

        #20;

        $finish;

    end

endmodule