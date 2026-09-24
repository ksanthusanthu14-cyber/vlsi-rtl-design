`timescale 1ns/1ps

module data_source #(
    parameter integer DATA_WIDTH = 8
)(
    input  logic                  clk,
    input  logic                  rst,
    input  logic                  enable,

    output logic [DATA_WIDTH-1:0] data,
    output logic                  valid
);

    // Enable directly represents a valid sample request.
    assign valid = enable;

    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin
            data <= {{(DATA_WIDTH-1){1'b0}}, 1'b1};
        end

        else if (enable) begin
            data <= data + 1'b1;
        end

    end

endmodule