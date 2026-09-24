module uart_rx_tb;

reg clk;
reg rst;
reg rx;

wire [7:0] rx_data;
wire data_valid;
wire busy;

uart_rx #(
    .DATA_WIDTH(8),
    .CLKS_PER_BIT(4)
) dut (
    .clk(clk),
    .rst(rst),
    .rx(rx),
    .rx_data(rx_data),
    .data_valid(data_valid),
    .busy(busy)
);

// ------------------------------------------------
// Clock
// ------------------------------------------------

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

// ------------------------------------------------
// Waveform
// ------------------------------------------------

initial begin

    $dumpfile("uart_rx_tb.vcd");
    $dumpvars(0, uart_rx_tb);

    $monitor(
        "Time=%0t | rx=%b | data=%h | valid=%b | busy=%b | state=%0d | bit=%0d | baud_count=%0d",
        $time,
        rx,
        rx_data,
        data_valid,
        busy,
        dut.state,
        dut.bit_index,
        dut.baud_counter
    );

end

// ------------------------------------------------
// UART bit task
// ------------------------------------------------

task send_bit;

    input bit_value;

    begin

        rx = bit_value;

        // One UART bit = 4 clock cycles
        #40;

    end

endtask

// ------------------------------------------------
// UART byte task
// ------------------------------------------------

task send_byte;

    input [7:0] data;

    begin

        // Start bit
        send_bit(1'b0);

        // Data bits - LSB first
        send_bit(data[0]);
        send_bit(data[1]);
        send_bit(data[2]);
        send_bit(data[3]);
        send_bit(data[4]);
        send_bit(data[5]);
        send_bit(data[6]);
        send_bit(data[7]);

        // Stop bit
        send_bit(1'b1);

    end

endtask

// ------------------------------------------------
// Test
// ------------------------------------------------

initial begin

    rst = 1;
    rx = 1'b1;

    #20;

    rst = 0;

    // --------------------------------------------
    // Send 0xA5
    // --------------------------------------------

    #20;

    send_byte(8'hA5);

    #40;

    // --------------------------------------------
    // Send 0x3C
    // --------------------------------------------

    send_byte(8'h3C);

    #80;

    $finish;

end

endmodule