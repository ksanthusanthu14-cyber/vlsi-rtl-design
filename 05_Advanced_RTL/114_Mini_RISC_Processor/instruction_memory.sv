`timescale 1ns/1ps

module instruction_memory (

    input  logic [7:0]  address,

    output logic [15:0] instruction

);

    logic [15:0] memory [0:255];

    always_comb begin
        instruction = memory[address];
    end

endmodule