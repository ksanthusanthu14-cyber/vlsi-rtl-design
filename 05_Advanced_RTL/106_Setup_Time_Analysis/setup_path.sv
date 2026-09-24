`timescale 1ns/1ps

// ============================================================
// PROJECT 106 - SETUP TIME ANALYSIS
//
// Educational timing model:
//
// Launch FF
//    |
//    | Tcq
//    v
// Combinational Path
//    |
//    | Tcomb
//    v
// Capture FF
//
// Setup requirement:
//
// Tclk >= Tcq + Tcomb + Tsetup
//
// Setup Slack:
//
// Slack = Tclk - (Tcq + Tcomb + Tsetup)
// ============================================================

module setup_path #(
    parameter integer TCQ       = 1,
    parameter integer TCOMB     = 3,
    parameter integer TSETUP    = 1
)(
    input  logic clk,
    input  logic rst,
    input  logic d,

    output logic launch_q,
    output logic data_arrival,
    output logic capture_q
);

    // --------------------------------------------------------
    // Launch flip-flop
    // --------------------------------------------------------

    always @(posedge clk) begin

        if (rst) begin

            launch_q <= 1'b0;

        end
        else begin

            launch_q <= #TCQ d;

        end

    end


    // --------------------------------------------------------
    // Combinational timing path
    // --------------------------------------------------------

    assign #(TCOMB) data_arrival = launch_q;


    // --------------------------------------------------------
    // Capture flip-flop
    // --------------------------------------------------------

    always @(posedge clk) begin

        if (rst) begin

            capture_q <= 1'b0;

        end
        else begin

            capture_q <= data_arrival;

        end

    end

endmodule