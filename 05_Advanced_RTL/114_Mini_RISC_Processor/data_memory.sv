`timescale 1ns/1ps

module data_memory (

    input  logic       clk,
    input  logic       rst,

    input  logic       mem_read,
    input  logic       mem_write,

    input  logic [7:0] address,
    input  logic [7:0] write_data,

    output logic [7:0] read_data

);

    logic [7:0] memory [0:255];

    integer i;

    always_comb begin

        if (mem_read)
            read_data = memory[address];
        else
            read_data = 8'd0;

    end

    always_ff @(posedge clk) begin

        if (rst) begin

            for (i = 0; i < 256; i = i + 1)
                memory[i] <= 8'd0;

        end
        else begin

            if (mem_write)
                memory[address] <= write_data;

        end

    end

endmodule