module moore(clk,rst,y);
input clk,rst;
output reg y;
reg [1:0]state;
parameter s0=2'b00,s1=2'b01,s2=2'b10,s3=2'b11;
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
            s2:state<=s3;
            s3:state<=s0;
            default : state<=s0;
        endcase
    end
end
//output logic (moore)
always @(*)
begin
    case(state)
        s0:y=1'b0;
        s1:y=1'b0;
        s2:y=1'b1;
        s3:y=1'b1;
        default : y=1'b0;
    endcase
end
endmodule