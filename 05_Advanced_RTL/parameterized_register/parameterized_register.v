module parameterized_register #(
    parameter WIDTH = 16
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             load,
    input  wire [WIDTH-1:0] data_in,
    output reg  [WIDTH-1:0] data_out
);

always @(posedge clk or posedge rst) begin
    if (rst)
        data_out <= {WIDTH{1'b0}};
    else if (load)
        data_out <= data_in;
end

endmodule