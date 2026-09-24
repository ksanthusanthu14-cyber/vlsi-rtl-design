`timescale 1ns/1ps

module protocol_slave (

    input  logic       clk,
    input  logic       rst,

    input  logic       req,
    input  logic [7:0] data_in,

    output logic       ack,
    output logic [7:0] data_out,
    output logic       data_valid

);

    logic req_seen;


    always_ff @(posedge clk or posedge rst) begin

        if (rst) begin

            ack        <= 0;
            data_out   <= 0;
            data_valid <= 0;

            req_seen   <= 0;

        end

        else begin

            ack        <= 0;
            data_valid <= 0;


            if (req && !req_seen) begin

                data_out <= data_in;

                ack <= 1;

                data_valid <= 1;

                req_seen <= 1;

            end


            if (!req) begin

                req_seen <= 0;

            end

        end

    end

endmodule