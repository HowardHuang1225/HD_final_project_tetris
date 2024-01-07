`include "definitions.vh"

module vga_display(
    input wire                                   clk,
    input wire [`BITS_PER_BLOCK-1:0]             cur_piece,
    input wire [`BITS_BLK_POS-1:0]               cur_blk_1,
    input wire [`BITS_BLK_POS-1:0]               cur_blk_2,
    input wire [`BITS_BLK_POS-1:0]               cur_blk_3,
    input wire [`BITS_BLK_POS-1:0]               cur_blk_4,
    input wire [(`BLOCKS_WIDE*`BLOCKS_HIGH)-1:0] fallen_pieces,
    output reg [11:0]                            rgb,
    output wire                                  hsync,
    output wire                                  vsync,
    input wire                                   sw_inferno,
    input wire pause,
    input wire rst
    );

    reg game_clk;
    reg [31:0] counter;
        
    always @ (posedge clk) begin
        if (!pause) begin
            if (rst) begin
                counter <= 0;
                game_clk <= 0;
            end else begin
                if (counter >= 50000000) begin // 1 Hz
                    counter <= 0;
                    game_clk <= 0;
                end
                else if (counter >= 25000000) begin // 1 Hz
                    counter <= (counter + 1);
                    game_clk <= 1;
                end 
                
                else begin
                    counter <= (counter + 1);
                    game_clk <= 0;
                end
            end
        end
    end



    reg [9:0] counter_x = 0;
    reg [9:0] counter_y = 0;
 
    assign hsync = ~(counter_x >= (`PIXEL_WIDTH + `HSYNC_FRONT_PORCH) &&
                     counter_x < (`PIXEL_WIDTH + `HSYNC_FRONT_PORCH + `HSYNC_PULSE_WIDTH));
    assign vsync = ~(counter_y >= (`PIXEL_HEIGHT + `VSYNC_FRONT_PORCH) &&
                     counter_y < (`PIXEL_HEIGHT + `VSYNC_FRONT_PORCH + `VSYNC_PULSE_WIDTH));

    // Combinational logic to select the current pixel
    wire [9:0] cur_blk_index = ((counter_x-`BOARD_X)/`BLOCK_SIZE) + (((counter_y-`BOARD_Y)/`BLOCK_SIZE)*`BLOCKS_WIDE);
    reg [2:0] cur_vid_mem;
    always @ (*) begin
        // Check if we're within the drawing space
        if (counter_x >= `BOARD_X && counter_y >= `BOARD_Y && counter_x <= `BOARD_X + `BOARD_WIDTH && counter_y <= `BOARD_Y + `BOARD_HEIGHT) begin
            if (counter_x == `BOARD_X || counter_x == `BOARD_X + `BOARD_WIDTH || counter_y == `BOARD_Y || counter_y == `BOARD_Y + `BOARD_HEIGHT) begin
                // We're at the edge of the board, paint it white
                //*![*]my modify
                //rgb = `WHITE;
                case (cur_piece)
                    `EMPTY_BLOCK: rgb = `GRAY;
                    `I_BLOCK: rgb = `CYAN;
                    `O_BLOCK: rgb = `YELLOW;
                    `T_BLOCK: rgb = `PURPLE;
                    `S_BLOCK: rgb = `GREEN;
                    `Z_BLOCK: rgb = `RED;
                    `J_BLOCK: rgb = `BLUE;
                    `L_BLOCK: rgb = `ORANGE;
                endcase
            end else begin
                if (cur_blk_index == cur_blk_1 ||
                    cur_blk_index == cur_blk_2 ||
                    cur_blk_index == cur_blk_3 ||
                    cur_blk_index == cur_blk_4) begin
                    case (cur_piece)
                        `EMPTY_BLOCK: rgb = `GRAY;
                        `I_BLOCK: rgb = (sw_inferno && game_clk) ?`BLACK:`CYAN;
                        `O_BLOCK: rgb = (sw_inferno && game_clk) ?`BLACK:`YELLOW;
                        `T_BLOCK: rgb = (sw_inferno && game_clk) ?`BLACK:`PURPLE;
                        `S_BLOCK: rgb = (sw_inferno && game_clk) ?`BLACK:`GREEN;
                        `Z_BLOCK: rgb = (sw_inferno && game_clk) ?`BLACK:`RED;
                        `J_BLOCK: rgb = (sw_inferno && game_clk) ?`BLACK:`BLUE;
                        `L_BLOCK: rgb = (sw_inferno && game_clk) ?`BLACK:`ORANGE;
                    endcase
                end else begin
                    rgb = fallen_pieces[cur_blk_index] ?  sw_inferno ?`PINK:`WHITE : sw_inferno ? `BLACK : `GRAY;
                end
            end
        end else begin
            // Outside the board
            rgb = `BLACK;
        end
    end

   always @ (posedge clk) begin
       if (counter_x >= `PIXEL_WIDTH + `HSYNC_FRONT_PORCH + `HSYNC_PULSE_WIDTH + `HSYNC_BACK_PORCH) begin
           counter_x <= 0;
           if (counter_y >= `PIXEL_HEIGHT + `VSYNC_FRONT_PORCH + `VSYNC_PULSE_WIDTH + `VSYNC_BACK_PORCH) begin
               counter_y <= 0;
           end else begin
               counter_y <= counter_y + 1;
           end
       end else begin
           counter_x <= counter_x + 1;
       end
   end

    

endmodule
