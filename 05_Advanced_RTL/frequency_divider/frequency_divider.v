module frequency_divider #(
    parameter DIVIDE = 4
)(
    input  wire clk,
    input  wire rst,
    output reg  clk_out
);

reg [31:0] counter;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        counter <= 32'd0;
        clk_out <= 1'b0;
    end
    else begin
        if (counter == (DIVIDE/2)-1) begin
            counter <= 32'd0;
            clk_out <= ~clk_out;
        end
        else begin
            counter <= counter + 1'b1;
        end
    end
end

endmodule