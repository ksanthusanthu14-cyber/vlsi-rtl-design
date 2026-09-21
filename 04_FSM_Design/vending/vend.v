module vend(clk,rst,coin5,coin10,dispense);
input clk,rst,coin5,coin10;
output reg dispense;
reg [1:0]state;
parameter S0=2'b00,S1=2'b01,S2=2'b10;
always @(posedge clk or posedge rst)
begin
    if (rst)
    begin
        state<=S0;
    end
    else
    begin
        case(state)
            S0:begin
                if (coin10)
                    state<=S2;
                else if (coin5)
                    state<=S1;
                else
                    state<=S0;
            end
            S1:begin
                if (coin5 || coin10)
                    state<=S2;
                else 
                    state<=S1;
            end
            S2:begin
                    state<=S0;
            end
            default:begin
                    state<=S0;
            end
        endcase
    end
end
always @(*)
begin
    case(state)
        S0:dispense=0;
        S1:dispense=0;
        S2:dispense=1;
        default:dispense=0;
    endcase
end
endmodule
