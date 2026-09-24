`timescale 1ns/1ps

module register_file (

    input  logic       clk,
    input  logic       rst,

    input  logic [2:0] read_addr1,
    input  logic [2:0] read_addr2,

    input  logic [2:0] write_addr,
    input  logic [7:0] write_data,

    input  logic       reg_write,

    output logic [7:0] read_data1,
    output logic [7:0] read_data2

);

    logic [7:0] regs [0:7];

    integer i;

    always_comb begin

        if (read_addr1 == 3'd0)
            read_data1 = 8'd0;
        else
            read_data1 = regs[read_addr1];

        if (read_addr2 == 3'd0)
            read_data2 = 8'd0;
        else
            read_data2 = regs[read_addr2];

    end


    always_ff @(posedge clk) begin

        if (rst) begin

            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 8'd0;

        end
        else begin

            if (reg_write && (write_addr != 3'd0))
                regs[write_addr] <= write_data;

            regs[0] <= 8'd0;

        end

    end

endmodule