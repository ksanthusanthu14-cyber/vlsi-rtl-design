module elev(clk,rst,up,down,motor_up,motor_down);
input clk,rst,up,down;
output reg motor_up,motor_down;
reg state;
parameter S0=1'b0,S1=1'b1;
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
                if (up)
                    state<=S1;
                else
                    state<=S0;
            end
            S1:begin
                if (down)
                    state<=S0;
                else
                    state<=S1;
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
        S0:begin
            if (up)
            begin
                motor_up=1;
                motor_down=0;
            end
            else
            begin
                motor_up=0;
                motor_down=0;
            end
        end
        S1:begin
            if (down)
            begin
                motor_up=0;
                motor_down=1;
            end
            else
            begin
                motor_up=0;
                motor_down=0;
            end
        end
        default:begin
            motor_up=0;
            motor_down=0;
        end
    endcase
end
endmodule