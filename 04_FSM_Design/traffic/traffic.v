module traffic(clk,rst,highway,side);
input clk,rst;
output reg [1:0] highway,side;
reg [1:0] state;
parameter s0=2'b00,s1=2'b01,s2=2'b10;
//state transition
always @(posedge clk or posedge rst)
begin
    if(rst)
        state<=s0;
    else
    begin
        case(state)
            s0:state<=s1;
            s1:state<=s2;
            s2:state<=s0;
            default : state<=s0;
        endcase
    end
end
//output logic (moore)
always @(*)
begin
    case(state)
        s0:begin
            highway=2'b10;
            side=2'b00;
        end
        s1:begin
            highway=2'b01;
            side=2'b00;
        end
        s2:begin
            highway=2'b00;
            side=2'b10;
        end
        default : begin
            highway=2'b00;
            side=2'b00;
        end
    endcase
end
endmodule