`timescale 1ns/1ps

module data_acquisition #(
    parameter integer DATA_WIDTH = 8,
    parameter integer FIFO_DEPTH = 8
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  source_enable,
    input  logic                  consumer_read,

    output logic [DATA_WIDTH-1:0] data_out,
    output logic                  data_valid,

    output logic                  fifo_full,
    output logic                  fifo_empty,

    output logic [$clog2(FIFO_DEPTH+1)-1:0] fifo_count,

    output logic                  overflow,
    output logic                  underflow
);

    logic [DATA_WIDTH-1:0] source_data;
    logic                  source_valid;

    logic                  read_accept;


    // ============================================================
    // DATA SOURCE
    // ============================================================

    data_source #(
        .DATA_WIDTH(DATA_WIDTH)
    ) u_source (
        .clk    (clk),
        .rst    (rst),

        .enable (source_enable),

        .data   (source_data),
        .valid  (source_valid)
    );


    // ============================================================
    // FIFO
    // ============================================================

    data_fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) u_fifo (
        .clk       (clk),
        .rst       (rst),

        .wr_en     (source_valid),
        .wr_data   (source_data),

        .rd_en     (consumer_read),
        .rd_data   (data_out),

        .full      (fifo_full),
        .empty     (fifo_empty),

        .count     (fifo_count),

        .overflow  (overflow),
        .underflow (underflow)
    );


    // ============================================================
    // READ ACCEPT
    // ============================================================

    always_comb begin

        read_accept = consumer_read && !fifo_empty;

    end


    // ============================================================
    // DATA VALID
    //
    // Registered to indicate that a valid FIFO read occurred on
    // the previous clock edge.
    // ============================================================

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            data_valid <= 1'b0;
        end

        else begin
            data_valid <= read_accept;
        end

    end

endmodule