module pulse_generator #(
    parameter PULSE_WIDTH = 4
)(
    input  wire clk,
    input  wire rst,
    input  wire trigger,
    output reg  pulse
);

reg [31:0] counter;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        pulse   <= 1'b0;
        counter <= 32'd0;
    end
    else begin

        if (!pulse) begin
            if (trigger) begin
                pulse   <= 1'b1;
                counter <= 32'd1;
            end
        end
        else begin
            if (counter == PULSE_WIDTH) begin
                pulse   <= 1'b0;
                counter <= 32'd0;
            end
            else begin
                counter <= counter + 1'b1;
            end
        end

    end
end

endmodule