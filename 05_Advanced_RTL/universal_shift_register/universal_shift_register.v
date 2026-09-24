module universal_shift_register #(
    parameter WIDTH = 4
)(
    input  wire                 clk,
    input  wire                 rst,
    input  wire [1:0]           mode,
    input  wire                 serial_in_left,
    input  wire                 serial_in_right,
    input  wire [WIDTH-1:0]     parallel_in,
    output reg  [WIDTH-1:0]     data_out
);

always @(posedge clk or posedge rst) begin
    if (rst) begin
        data_out <= {WIDTH{1'b0}};
    end
    else begin
        case (mode)

            2'b00: begin
                // Hold
                data_out <= data_out;
            end

            2'b01: begin
                // Shift right
                data_out <= {serial_in_left, data_out[WIDTH-1:1]};
            end

            2'b10: begin
                // Shift left
                data_out <= {data_out[WIDTH-2:0], serial_in_right};
            end

            2'b11: begin
                // Parallel load
                data_out <= parallel_in;
            end

            default: begin
                data_out <= data_out;
            end

        endcase
    end
end

endmodule