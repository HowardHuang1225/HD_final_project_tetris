`include "definitions.vh"

module calc_test_pos_rot(
    input wire [`MODE_BITS-1:0]  mode,
    input wire                   game_clk_rst,
    input wire                   game_clk,
    
    input wire [`BITS_X_POS-1:0] cur_pos_x,
    input wire [`BITS_Y_POS-1:0] cur_pos_y,
    input wire [`BITS_ROT-1:0]   cur_rot,
    output reg [`BITS_X_POS-1:0] test_pos_x,
    output reg [`BITS_Y_POS-1:0] test_pos_y,
    output reg [`BITS_ROT-1:0]   test_rot,
    input wire been_ready,
    input wire [511:0] last_change,
    input wire [8:0] key_down,
    input wire [2:0] piece
    );
// input wire                   btn_left_en,
//     input wire                   btn_right_en,
//     input wire                   btn_rotate_en,
//     input wire                   btn_down_en,
//     input wire                   btn_drop_en,
    always @ (*) begin
        if (mode == `MODE_PLAY) begin
            if (game_clk) begin
                test_pos_x = cur_pos_x;
                test_pos_y = cur_pos_y + 1; // move down
                test_rot = cur_rot;
            end else if ((been_ready && key_down[last_change] && last_change==9'b0_0001_1100)) begin
                test_pos_x = cur_pos_x - 1; // move left
                test_pos_y = cur_pos_y;
                test_rot = cur_rot;
            end else if ((been_ready && key_down[last_change] && last_change==9'b0_0010_0011)) begin
                test_pos_x = cur_pos_x + 1; // move right
                test_pos_y = cur_pos_y;
                test_rot = cur_rot;
            end else if ((been_ready && key_down[last_change] && last_change==9'b0_0001_1101)) begin
                if (piece == `I_BLOCK) begin
                    if (cur_rot == 3) begin
                        test_pos_x <= cur_pos_x + 1;
                        if (cur_pos_y > 0) test_pos_y <= cur_pos_y - 1;
                        else test_pos_y <= cur_pos_y;
                    end 
                    else if (cur_rot == 0) begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 2)
                            test_pos_x <= `BLOCKS_WIDE - 4;
                        else if (cur_pos_x < 1)
                            test_pos_x <= 1;
                        else test_pos_x <= cur_pos_x - 1;
                        test_pos_y <= cur_pos_y + 1;
                    end
                    else if (cur_rot == 1) begin
                        test_pos_x <= cur_pos_x + 2;
                        test_pos_y <= cur_pos_y - 2;
                    end 
                    else begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 1)
                            test_pos_x <= `BLOCKS_WIDE - 4;
                        else if (cur_pos_x < 2)
                            test_pos_x <= 1;
                        else test_pos_x <= cur_pos_x - 2;
                        test_pos_y <= cur_pos_y + 2;
                    end
                end
                else if (piece == `T_BLOCK) begin
                    if (cur_rot == 0) begin
                        test_pos_x <= cur_pos_x;
                        if (cur_pos_y > 0) test_pos_y <= cur_pos_y - 1;
                        else test_pos_y <= cur_pos_y;
                    end 
                    else if (cur_rot == 1) begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 2)
                            test_pos_x <= `BLOCKS_WIDE - 3;
                        else test_pos_x <= cur_pos_x;
                        test_pos_y <= cur_pos_y;
                    end
                    else if (cur_rot == 2) begin
                        test_pos_x <= cur_pos_x + 1;
                        test_pos_y <= cur_pos_y;
                    end 
                    else begin
                        if (cur_pos_x > 0) test_pos_x <= cur_pos_x - 1;
                        else test_pos_x <= 0;
                        test_pos_y <= cur_pos_y + 1;
                    end
                end else if (piece == `S_BLOCK) begin
                    if (cur_rot == 0) begin
                        test_pos_x <= cur_pos_x;
                        test_pos_y <= cur_pos_y;
                    end 
                    else if (cur_rot == 1) begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 2)
                            test_pos_x <= `BLOCKS_WIDE - 3;
                        else test_pos_x <= cur_pos_x;
                        test_pos_y <= cur_pos_y + 1;
                    end
                    else if (cur_rot == 2) begin
                        test_pos_x <= cur_pos_x + 1;
                        if (cur_pos_y > 0) test_pos_y <= cur_pos_y - 1;
                        else test_pos_y <= cur_pos_y;
                    end 
                    else begin
                        if (cur_pos_x > 0) test_pos_x <= cur_pos_x - 1;
                        else test_pos_x <= cur_pos_x;
                        test_pos_y <= cur_pos_y;
                    end
                end else if (piece == `Z_BLOCK) begin
                    if (cur_rot == 0) begin
                        test_pos_x <= cur_pos_x;
                        test_pos_y <= cur_pos_y;
                    end 
                    else if (cur_rot == 1) begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 2)
                            test_pos_x <= `BLOCKS_WIDE - 3;
                        else test_pos_x <= cur_pos_x;
                        test_pos_y <= cur_pos_y + 1;
                    end
                    else if (cur_rot == 2) begin
                        test_pos_x <= cur_pos_x + 1;
                        if (cur_pos_y > 0) test_pos_y <= cur_pos_y - 1;
                        else test_pos_y <= cur_pos_y;
                    end 
                    else begin
                        if (cur_pos_x > 0) test_pos_x <= cur_pos_x - 1;
                        else test_pos_x <= cur_pos_x;
                        test_pos_y <= cur_pos_y;
                    end
                end else if (piece == `J_BLOCK) begin
                    if (cur_rot == 0) begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 2) test_pos_x <= `BLOCKS_WIDE - 3;
                        else test_pos_x <= cur_pos_x;
                        test_pos_y <= cur_pos_y;
                    end 
                    else if (cur_rot == 1) begin
                        test_pos_x <= cur_pos_x + 1;
                        test_pos_y <= cur_pos_y;
                    end
                    else if (cur_rot == 2) begin
                        if (cur_pos_x > 0) test_pos_x <= cur_pos_x - 1;
                        else test_pos_x <= cur_pos_x;
                        test_pos_y <= cur_pos_y + 1;
                    end 
                    else begin
                        test_pos_x<= cur_pos_x;
                        if (cur_pos_y > 0) test_pos_y <= cur_pos_y - 1;
                        else test_pos_y <= cur_pos_y;
                    end
                end else if (piece == `L_BLOCK) begin
                    if (cur_rot == 0) begin
                        if (cur_pos_x > 0) test_pos_x <= cur_pos_x - 1;
                        else test_pos_x <= cur_pos_x;
                        test_pos_y <= cur_pos_y + 1;
                    end 
                    else if (cur_rot == 1) begin
                        test_pos_x <= cur_pos_x;
                        if (cur_pos_y > 0) test_pos_y <= cur_pos_y - 1;
                        else test_pos_y <= cur_pos_y;
                    end
                    else if (cur_rot == 2) begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 2) test_pos_x <= `BLOCKS_WIDE - 3;
                        else test_pos_x <= cur_pos_x;
                        test_pos_y <= cur_pos_y;
                    end 
                    else begin
                        test_pos_x <= cur_pos_x + 1;
                        test_pos_y <= cur_pos_y;
                    end
                end
                test_rot <= cur_rot + 1;
            end else if ((been_ready && key_down[last_change] && last_change==9'b0_0001_1011)) begin
                test_pos_x = cur_pos_x;
                test_pos_y = cur_pos_y + 1; // move down
                test_rot = cur_rot;
            end else if ((been_ready && key_down[last_change] && last_change == 9'b0_0010_1001)) begin
                // do nothing, we set to drop mode
                test_pos_x = cur_pos_x;
                test_pos_y = cur_pos_y;
                test_rot = cur_rot;
            end else begin
                // do nothing, the block isn't moving this cycle
                test_pos_x = cur_pos_x;
                test_pos_y = cur_pos_y;
                test_rot = cur_rot;
            end
        end else if (mode == `MODE_DROP) begin
            if (game_clk_rst) begin
                // do nothing, we set to play mode
                test_pos_x = cur_pos_x;
                test_pos_y = cur_pos_y;
                test_rot = cur_rot;
            end else begin
                test_pos_x = cur_pos_x;
                test_pos_y = cur_pos_y + 1; // move down
                test_rot = cur_rot;
            end
        end else begin
            // Other mode, do nothing
            test_pos_x = cur_pos_x;
            test_pos_y = cur_pos_y;
            test_rot = cur_rot;
        end
    end

endmodule
