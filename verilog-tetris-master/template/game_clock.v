module game_clock(
    input wire clk,
    input wire rst,
    input wire pause,
    output reg game_clk,
    input [3:0] score1,
    input [3:0] score2,
    input [3:0] score3,
    input [3:0] score4,
    input wire sw_inferno
    );

    reg [31:0] counter;
    reg [31:0] tmp;
    //50000000;
    //25000000;
    always @(*) begin
        if(rst) begin
            tmp = 25000000;
        end
        if(!sw_inferno) begin
            if((score1+score2*10+score3*100+score4*1000) < 10) begin
                tmp = 25000000;
            end
            else if((score1+score2*10+score3*100+score4*1000)>=10 && (score1+score2*10+score3*100+score4*1000)<20) begin
                tmp = 12500000;
            end
            else if((score1+score2*10+score3*100+score4*1000)>=20 && (score1+score2*10+score3*100+score4*1000)<30) begin
                tmp = 6250000;
            end
            else if((score1+score2*10+score3*100+score4*1000) >=30 && (score1+score2*10+score3*100+score4*1000)<40) begin
                tmp = 5000000;
            end
            else if((score1+score2*10+score3*100+score4*1000) >=40 && (score1+score2*10+score3*100+score4*1000)<50) begin
                tmp = 2500000;
            end
            else begin
                tmp = 1250000;
            end
        end
        else begin
            tmp = 5000000;
        end
    end


    always @ (posedge clk) begin
        if (!pause) begin
            if (rst) begin
                counter <= 0;
                game_clk <= 0;
            end else begin
                if (counter >= tmp) begin // 1 Hz
                    counter <= 0;
                    game_clk <= 1;
                end else begin
                    counter <= (counter + 1);
                    game_clk <= 0;
                end
            end
        end
    end



endmodule
