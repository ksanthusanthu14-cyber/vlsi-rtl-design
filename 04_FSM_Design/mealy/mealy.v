module mealy(clk,rst,x,y);
input clk,rst,x;
output reg y;
reg state;
parameter s0=2'b0,s1=2'b1;
//state transition
always @(posedge clk or posedge rst)
begin
    if(rst)
        state<=s0;
    else
    begin
        case(state)
        s0:
            if(x==1'b1)
                state<=s1;
            else
                state<=s0;
        s1:
            if(x==1'b1)
                state<=s1;
            else
                state<=s0;
        default : state<=s0;
        endcase
    end
end
//output logic (mealy)
always @(*)
begin
    case(state)
        s0:
            if(x==1'b1)
                y=1'b1;
            else
                y=1'b0;
        s1:
            if(x==1'b1)
                y=1'b0;
            else
                y=1'b1;
        default : y=1'b0;
    endcase
end 
endmodule