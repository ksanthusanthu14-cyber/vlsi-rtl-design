module apb_master #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32
)(
    input  logic                  clk,
    input  logic                  rst,

    input  logic                  start,
    input  logic                  write_en,
    input  logic [ADDR_WIDTH-1:0] addr,
    input  logic [DATA_WIDTH-1:0] wdata,

    output logic [DATA_WIDTH-1:0] rdata,
    output logic                  done,
    output logic                  busy,

    output logic                  psel,
    output logic                  penable,
    output logic                  pwrite,
    output logic [ADDR_WIDTH-1:0] paddr,
    output logic [DATA_WIDTH-1:0] pwdata,

    input  logic [DATA_WIDTH-1:0] prdata,
    input  logic                  pready,
    input  logic                  pslverr
);

    typedef enum logic [1:0] {
        IDLE,
        SETUP,
        ACCESS
    } state_t;

    state_t state;

    always_ff @(posedge clk) begin

        if (rst) begin
            state   <= IDLE;

            rdata   <= '0;
            done    <= 1'b0;
            busy    <= 1'b0;

            psel    <= 1'b0;
            penable <= 1'b0;
            pwrite  <= 1'b0;
            paddr   <= '0;
            pwdata  <= '0;
        end

        else begin

            done <= 1'b0;

            case (state)

                IDLE: begin

                    psel    <= 1'b0;
                    penable <= 1'b0;
                    busy    <= 1'b0;

                    if (start) begin

                        paddr  <= addr;
                        pwdata <= wdata;
                        pwrite <= write_en;

                        busy <= 1'b1;

                        state <= SETUP;
                    end
                end


                SETUP: begin

                    psel    <= 1'b1;
                    penable <= 1'b0;

                    state <= ACCESS;
                end


                ACCESS: begin

                    psel    <= 1'b1;
                    penable <= 1'b1;

                    if (pready) begin

                        if (!pwrite)
                            rdata <= prdata;

                        done <= 1'b1;
                        busy <= 1'b0;

                        psel    <= 1'b0;
                        penable <= 1'b0;

                        state <= IDLE;
                    end
                end

                default: begin
                    state <= IDLE;
                end

            endcase
        end
    end

endmodule