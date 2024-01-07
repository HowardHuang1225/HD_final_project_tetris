`include "definitions.vh"

module tetris(
    input wire        clk,
    input wire        btn_rst,
    input wire        btn_volup,
    input wire        btn_voldown,
    input wire        btn_start,
    input wire        btn_cheat,
    input wire        sw_pause,
    input wire        sw_mute,
    input wire        sw_inferno,
    output wire [3:0] vgaRed,
    output wire [3:0] vgaGreen,
    output wire [3:0] vgaBlue,
    output wire       hsync,
    output wire       vsync,
    output wire [6:0] display,
    output wire [3:0] digit,
    inout wire        PS2_DATA,
	inout wire        PS2_CLK,
    output            audio_mclk, // master clock
    output            audio_lrck, // left-right clock
    output            audio_sck,  // serial clock
    output            audio_sdin, // serial audio data input
    output wire [15:0] LED
    );

    // The mode, used for finite state machine things. We also
    // need to store the old mode occasionally, like when we're paused.
    reg [`MODE_BITS-1:0] mode;
    reg [`MODE_BITS-1:0] old_mode;
    // The game clock
    wire game_clk;
    // The game clock reset
    reg game_clk_rst;

    wire [11:0] rgb;

    assign {vgaRed,vgaGreen,vgaBlue} = rgb;

    wire clkDiv22;
    wire clkDiv2;

    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clkDiv22));    // for audio
    clock_divider #(.n(2)) clock_2(.clk(clk), .clk_div(clkDiv2));    // for game、7seg


    wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;

    KeyboardDecoder key_de (
        .key_down({key_down}),
        .last_change(last_change),
        .key_valid(been_ready),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(btn_rst),
        .clk(clkDiv2)
	);



    

    // Increments once per cycle to a maximum value. If this is
    // not yet at the maximum value, we cannot go into drop mode.
    reg [31:0] drop_timer;
    initial begin
        drop_timer = 0;
    end

    // This signal random_piece rotates between the types
    // of pieces at 100 MHz, and is selected based on user input,
    // making it effectively random.
    wire [`BITS_PER_BLOCK-1:0] random_piece;
    randomizer randomizer_ (
        .clk(clkDiv2),
        .random(random_piece)
    );

    // The enable signals for the five buttons, after
    // they have gone through the debouncer. Should only be high
    // for one cycle for each button press.
    wire btn_rst_en;
    wire btn_volup_en;
    wire btn_voldown_en;
    wire btn_start_en;
    wire btn_cheat_en;

    // Debounce all of the input signals
    debouncer debouncer_btn_rst_ (
        .raw(btn_rst),
        .clk(clkDiv2),
        .enabled(btn_rst_en)
    );
    debouncer debouncer_btn_volup_ (
        .raw(btn_volup),
        .clk(clkDiv2),
        .enabled(btn_volup_en)
    );
    debouncer debouncer_btn_voldown_ (
        .raw(btn_voldown),
        .clk(clkDiv2),
        .enabled(btn_voldown_en)
    );
    debouncer debouncer_btn_start_ (
        .raw(btn_start),
        .clk(clkDiv2),
        .enabled(btn_start_en)
    );
    debouncer debouncer_btn_cheat_ (
        .raw(btn_cheat),
        .clk(clkDiv2),
        .enabled(btn_rst_cheat)
    );


    wire rst_1pulse;
    wire volup_1pulse;
    wire voldown_1pulse;
    wire start_1pulse;
    wire cheat_1pulse;
    one_pulse op1 (.pb_in(btn_rst_en), .clk(clkDiv2), .pb_out(rst_1pulse));
    one_pulse op2 (.pb_in(btn_volup_en), .clk(clkDiv2), .pb_out(volup_1pulse));
    one_pulse op3 (.pb_in(btn_voldown_en), .clk(clkDiv2), .pb_out(voldown_1pulse));
    one_pulse op4 (.pb_in(btn_start_en), .clk(clkDiv2), .pb_out(start_1pulse));
    one_pulse op5 (.pb_in(btn_cheat_en), .clk(clkDiv2), .pb_out(cheat_1pulse));




    music music0(
    .clk(clk),
    .rst(btn_rst),        // BTNC: active high reset
    ._mute(mode!=`MODE_PLAY ? 1:sw_mute),      // SW14: Mute
    ._mode(mode),      // SW15: Mode
    ._volUP(btn_volup),     // BTNU: Vol up
    ._volDOWN(btn_voldown),   // BTND: Vol down
    .audio_mclk(audio_mclk), // master clock
    .audio_lrck(audio_lrck), // left-right clock
    .audio_sck(audio_sck),  // serial clock
    .audio_sdin(audio_sdin) // serial audio data input
    );      


    // A memory bank for storing 1 bit for each board position.
    // If the fallen_pieces memory is 1, there is a block still that
    // has not been removed from play. This is used to draw the board
    // and to test for intersection with the falling piece.
    reg [(`BLOCKS_WIDE*`BLOCKS_HIGH)-1:0] fallen_pieces;

    // What type of piece the current falling tetromino is. The types
    // are defined in definitions.vh.
    reg [`BITS_PER_BLOCK-1:0] cur_piece;
    // The x position of the falling piece.
    reg [`BITS_X_POS-1:0] cur_pos_x;
    // The y position of the falling piece.
    reg [`BITS_Y_POS-1:0] cur_pos_y;
    // The current rotation of the falling piece (0 == 0 degrees, 1 == 90 degrees, etc)
    reg [`BITS_ROT-1:0] cur_rot;
    // The four flattened locations of the current falling tetromino. Used to
    // test for intersection, or add to fallen_pieces, etc.
    wire [`BITS_BLK_POS-1:0] cur_blk_1;
    wire [`BITS_BLK_POS-1:0] cur_blk_2;
    wire [`BITS_BLK_POS-1:0] cur_blk_3;
    wire [`BITS_BLK_POS-1:0] cur_blk_4;
    // The width and height of the current shape of the tetromino, based on its
    // type and rotation.
    wire [`BITS_BLK_SIZE-1:0] cur_width;
    wire [`BITS_BLK_SIZE-1:0] cur_height;
    // Use a calc_cur_blk module to get the values of the wires above from
    // the current position, type, and rotation of the falling tetromino.
    calc_cur_blk calc_cur_blk_ (
        .piece(cur_piece),
        .pos_x(cur_pos_x),
        .pos_y(cur_pos_y),
        .rot(cur_rot),
        .blk_1(cur_blk_1),
        .blk_2(cur_blk_2),
        .blk_3(cur_blk_3),
        .blk_4(cur_blk_4),
        .width(cur_width),
        .height(cur_height)
    );

    // The VGA controller. We give it the type of tetromino (cur_piece)
    // so that it knows the right color, and the four positions on the
    // board that it covers. We also pass in fallen_pieces so that it can
    // display the fallen tetromino squares in monochrome.

    vga_display display_ (
        .clk(clkDiv2),
        .cur_piece(cur_piece),
        .cur_blk_1(cur_blk_1),
        .cur_blk_2(cur_blk_2),
        .cur_blk_3(cur_blk_3),
        .cur_blk_4(cur_blk_4),
        .fallen_pieces(fallen_pieces),
        .rgb(rgb),
        .hsync(hsync),
        .vsync(vsync),
        .sw_inferno(sw_inferno),
        .pause(mode != `MODE_PLAY)
        ,.rst(game_clk_rst)
    );

    
    reg [3:0] score_1; // 1's place
    reg [3:0] score_2; // 10's place
    reg [3:0] score_3; // 100's place
    reg [3:0] score_4; // 1000's place 

    // This module outputs the game clock, which is when the clock
    // that determines when the tetromino falls by itself.
    game_clock game_clock_ (
        .clk(clkDiv2),
        .rst(game_clk_rst),
        .pause(mode != `MODE_PLAY),
        .game_clk(game_clk),
        .score1(score_1),
        .score2(score_2),
        .score3(score_3),
        .score4(score_4),
        .sw_inferno(sw_inferno)
    );

    // Set up some variables to test for intersection or off-screen-ness
    // of the current piece if the user's current action were to be
    // followed through. For example, if the user presses the left button,
    // we test where the current piece would be if it was moved one to the
    // left, i.e. x = x - 1.
    // wire [`BITS_X_POS-1:0] test_pos_x;
    // wire [`BITS_Y_POS-1:0] test_pos_y;
    // wire [`BITS_ROT-1:0] test_rot;
    // // Combinational logic to determine what position/rotation we are testing.
    // // This has been hoisted out into a module so that the code is shorter.
    // calc_test_pos_rot calc_test_pos_rot_ (
    //     .mode(mode),
    //     .game_clk_rst(game_clk_rst),
    //     .game_clk(game_clk),
        
    //     .cur_pos_x(cur_pos_x),
    //     .cur_pos_y(cur_pos_y),
    //     .cur_rot(cur_rot),
    //     .test_pos_x(test_pos_x),
    //     .test_pos_y(test_pos_y),
    //     .test_rot(test_rot),
    //     .been_ready(been_ready),
    //     .last_change(last_change),
    //     .key_down(keydown)
    //     ,.piece(cur_piece)
    // );
    

     
    // wire [`BITS_BLK_POS-1:0] test_blk_1;
    // wire [`BITS_BLK_POS-1:0] test_blk_2;
    // wire [`BITS_BLK_POS-1:0] test_blk_3;
    // wire [`BITS_BLK_POS-1:0] test_blk_4;
    // wire [`BITS_BLK_SIZE-1:0] test_width;
    // wire [`BITS_BLK_SIZE-1:0] test_height;
    // calc_cur_blk calc_test_block_ (
    //     .piece(cur_piece),
    //     .pos_x(test_pos_x),
    //     .pos_y(test_pos_y),
    //     .rot(test_rot),
    //     .blk_1(test_blk_1),
    //     .blk_2(test_blk_2),
    //     .blk_3(test_blk_3),
    //     .blk_4(test_blk_4),
    //     .width(test_width),
    //     .height(test_height)
    // );

    // This function checks whether its input block positions intersect
    // with any fallen pieces.
    function intersects_fallen_pieces;
        input wire [7:0] blk1;
        input wire [7:0] blk2;
        input wire [7:0] blk3;
        input wire [7:0] blk4;
        begin
            intersects_fallen_pieces = fallen_pieces[blk1] ||
                                       fallen_pieces[blk2] ||
                                       fallen_pieces[blk3] ||
                                       fallen_pieces[blk4];
        end
    endfunction

    // This signal goes high when the test positions/rotations intersect with
    // fallen blocks.
    // wire test_intersects = intersects_fallen_pieces(test_blk_1, test_blk_2, test_blk_3, test_blk_4);

    // If the falling piece can be moved left, moves it left
    task move_left;
        begin
            if (cur_pos_x > 0 
            // && !test_intersects
            ) begin
                if (!fallen_pieces[cur_blk_1 - 1]
                && !fallen_pieces[cur_blk_2 - 1]
                && !fallen_pieces[cur_blk_3 - 1]
                && !fallen_pieces[cur_blk_4 - 1]
                )                
                cur_pos_x <= cur_pos_x - 1;
            end
        end
    endtask

    // If the falling piece can be moved right, moves it right
    task move_right;
        begin
            if (cur_pos_x + cur_width < `BLOCKS_WIDE
            //  && !test_intersects
             ) begin
                if (!fallen_pieces[cur_blk_1 + 1]
                && !fallen_pieces[cur_blk_2 + 1]
                && !fallen_pieces[cur_blk_3 + 1]
                && !fallen_pieces[cur_blk_4 + 1]
                )  
                cur_pos_x <= cur_pos_x + 1;
            end
        end
    endtask

    // Rotates the current block if it would not cause any part of the
    // block to go off screen and would not intersect with any fallen blocks.
        task rotate;
        begin
            if (cur_pos_x + cur_width <= `BLOCKS_WIDE &&
                cur_pos_y + cur_height <= `BLOCKS_HIGH
                // !test_intersects
                ) begin
                if (cur_piece == `I_BLOCK) begin
                    if (cur_rot == 3) begin
                        cur_pos_x <= cur_pos_x + 1;
                        if (cur_pos_y > 0) cur_pos_y <= cur_pos_y - 1;
                        else cur_pos_y <= cur_pos_y;
                    end 
                    else if (cur_rot == 0) begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 2)
                            cur_pos_x <= `BLOCKS_WIDE - 4;
                        else if (cur_pos_x < 1)
                            cur_pos_x <= 1;
                        else cur_pos_x <= cur_pos_x - 1;
                        cur_pos_y <= cur_pos_y + 1;
                    end
                    else if (cur_rot == 1) begin
                        cur_pos_x <= cur_pos_x + 2;
                        cur_pos_y <= cur_pos_y - 2;
                    end 
                    else begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 1)
                            cur_pos_x <= `BLOCKS_WIDE - 4;
                        else if (cur_pos_x < 2)
                            cur_pos_x <= 1;
                        else cur_pos_x <= cur_pos_x - 2;
                        cur_pos_y <= cur_pos_y + 2;
                    end
                end
                else if (cur_piece == `T_BLOCK) begin
                    if (cur_rot == 0) begin
                        cur_pos_x <= cur_pos_x;
                        if (cur_pos_y > 0) cur_pos_y <= cur_pos_y - 1;
                        else cur_pos_y <= cur_pos_y;
                    end 
                    else if (cur_rot == 1) begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 2)
                            cur_pos_x <= `BLOCKS_WIDE - 3;
                        else cur_pos_x <= cur_pos_x;
                        cur_pos_y <= cur_pos_y;
                    end
                    else if (cur_rot == 2) begin
                        cur_pos_x <= cur_pos_x + 1;
                        cur_pos_y <= cur_pos_y;
                    end 
                    else begin
                        if (cur_pos_x > 0) cur_pos_x <= cur_pos_x - 1;
                        else cur_pos_x <= 0;
                        cur_pos_y <= cur_pos_y + 1;
                    end
                end else if (cur_piece == `S_BLOCK) begin
                    if (cur_rot == 0) begin
                        cur_pos_x <= cur_pos_x;
                        cur_pos_y <= cur_pos_y;
                    end 
                    else if (cur_rot == 1) begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 2)
                            cur_pos_x <= `BLOCKS_WIDE - 3;
                        else cur_pos_x <= cur_pos_x;
                        cur_pos_y <= cur_pos_y + 1;
                    end
                    else if (cur_rot == 2) begin
                        cur_pos_x <= cur_pos_x + 1;
                        if (cur_pos_y > 0) cur_pos_y <= cur_pos_y - 1;
                        else cur_pos_y <= cur_pos_y;
                    end 
                    else begin
                        if (cur_pos_x > 0) cur_pos_x <= cur_pos_x - 1;
                        else cur_pos_x <= cur_pos_x;
                        cur_pos_y <= cur_pos_y;
                    end
                end else if (cur_piece == `Z_BLOCK) begin
                    if (cur_rot == 0) begin
                        cur_pos_x <= cur_pos_x;
                        cur_pos_y <= cur_pos_y;
                    end 
                    else if (cur_rot == 1) begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 2)
                            cur_pos_x <= `BLOCKS_WIDE - 3;
                        else cur_pos_x <= cur_pos_x;
                        cur_pos_y <= cur_pos_y + 1;
                    end
                    else if (cur_rot == 2) begin
                        cur_pos_x <= cur_pos_x + 1;
                        if (cur_pos_y > 0) cur_pos_y <= cur_pos_y - 1;
                        else cur_pos_y <= cur_pos_y;
                    end 
                    else begin
                        if (cur_pos_x > 0) cur_pos_x <= cur_pos_x - 1;
                        else cur_pos_x <= cur_pos_x;
                        cur_pos_y <= cur_pos_y;
                    end
                end else if (cur_piece == `J_BLOCK) begin
                    if (cur_rot == 0) begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 2) cur_pos_x <= `BLOCKS_WIDE - 3;
                        else cur_pos_x <= cur_pos_x;
                        cur_pos_y <= cur_pos_y;
                    end 
                    else if (cur_rot == 1) begin
                        cur_pos_x <= cur_pos_x + 1;
                        cur_pos_y <= cur_pos_y;
                    end
                    else if (cur_rot == 2) begin
                        if (cur_pos_x > 0) cur_pos_x <= cur_pos_x - 1;
                        else cur_pos_x <= cur_pos_x;
                        cur_pos_y <= cur_pos_y + 1;
                    end 
                    else begin
                        cur_pos_x<= cur_pos_x;
                        if (cur_pos_y > 0) cur_pos_y <= cur_pos_y - 1;
                        else cur_pos_y <= cur_pos_y;
                    end
                end else if (cur_piece == `L_BLOCK) begin
                    if (cur_rot == 0) begin
                        if (cur_pos_x > 0) cur_pos_x <= cur_pos_x - 1;
                        else cur_pos_x <= cur_pos_x;
                        cur_pos_y <= cur_pos_y + 1;
                    end 
                    else if (cur_rot == 1) begin
                        cur_pos_x <= cur_pos_x;
                        if (cur_pos_y > 0) cur_pos_y <= cur_pos_y - 1;
                        else cur_pos_y <= cur_pos_y;
                    end
                    else if (cur_rot == 2) begin
                        if (`BLOCKS_WIDE - cur_pos_x <= 2) cur_pos_x <= `BLOCKS_WIDE - 3;
                        else cur_pos_x <= cur_pos_x;
                        cur_pos_y <= cur_pos_y;
                    end 
                    else begin
                        cur_pos_x <= cur_pos_x + 1;
                        cur_pos_y <= cur_pos_y;
                    end
                end
                cur_rot <= cur_rot + 1;
            end
        end
    endtask

    // Adds the current block to fallen_pieces
    task add_to_fallen_pieces;
        begin
            fallen_pieces[cur_blk_1] <= 1;
            fallen_pieces[cur_blk_2] <= 1;
            fallen_pieces[cur_blk_3] <= 1;
            fallen_pieces[cur_blk_4] <= 1;
        end
    endtask

    // Adds the given blocks to fallen_pieces, and
    // chooses a new block for the user that appears
    // at the top of the screen.
    task get_new_block;
        begin
            // Reset the drop timer, can't drop until this is high enough
            drop_timer <= 0;
            // Choose a new block for the user
            cur_piece <= random_piece;
            cur_pos_x <= (`BLOCKS_WIDE / 2) - 1;
            cur_pos_y <= 0;
            cur_rot <= 0;
            // reset the game timer so the user has a full
            // cycle before the block falls
            game_clk_rst <= 1;
        end
    endtask

    // Moves the current piece down one, getting a new block if
    // the piece would go off the board or intersect with another block.
    task move_down;
        begin
            if (cur_pos_y + cur_height < `BLOCKS_HIGH
            //  && !test_intersects
                && (cur_blk_1 < 210 && !fallen_pieces[cur_blk_1 + `BLOCKS_WIDE])
                && (cur_blk_2 < 210 && !fallen_pieces[cur_blk_2 + `BLOCKS_WIDE])
                && (cur_blk_3 < 210 && !fallen_pieces[cur_blk_3 + `BLOCKS_WIDE])
                && (cur_blk_4 < 210 && !fallen_pieces[cur_blk_4 + `BLOCKS_WIDE])
            ) begin
                
                cur_pos_y <= cur_pos_y + 1;
            end else begin
                add_to_fallen_pieces();
                get_new_block();
            end
        end
    endtask

    // Sets the mode to MODE_DROP, in which the current block will not respond
    // to user input and it will move down at one cycle per second until it hits
    // a block or the bottom of the board.
    task drop_to_bottom;
        begin
            mode <= `MODE_DROP;
        end
    endtask

    // The score register, increased by one when the user
    // completes a row.
    // The 7-segment display module, which outputs the score
    seg_display score_display_ (
        .clk(clkDiv2),
        .score_1(mode!=`MODE_PLAY? mode==`MODE_OVER? 15: mode==`MODE_SUCCESS? 5:11: sw_inferno && mode == `MODE_PLAY ? 9:score_1),
        .score_2(mode!=`MODE_PLAY? mode==`MODE_OVER? 14: mode==`MODE_SUCCESS? 5:11: sw_inferno && mode == `MODE_PLAY ? 9:score_2),
        .score_3(mode!=`MODE_PLAY? mode==`MODE_OVER? 13: mode==`MODE_SUCCESS? 5:11: sw_inferno && mode == `MODE_PLAY ? 9:score_3),
        .score_4(mode!=`MODE_PLAY? mode==`MODE_OVER? 12: mode==`MODE_SUCCESS? 5:11: sw_inferno && mode == `MODE_PLAY ? 9:score_4),
        .an(digit),
        .seg(display)
    );


    assign LED = (mode==`MODE_SUCCESS)? 16'b1111_1111_1111_1111: 16'b0000_0000_0000_0000;


    // The module that determines which row, if any, is complete
    // and needs to be removed and the score incremented
    wire [`BITS_Y_POS-1:0] remove_row_y;
    wire remove_row_en;
    complete_row complete_row_ (
        .clk(clkDiv2),
        .pause(mode != `MODE_PLAY),
        .fallen_pieces(fallen_pieces),
        .row(remove_row_y),
        .enabled(remove_row_en)
    );

    // This task removes the completed row from fallen_pieces
    // and increments the score
    

    reg [15:0] score;
    reg [`BITS_Y_POS-1:0] shifting_row;
    task remove_row;
        begin
            // Shift away remove_row_y
            mode <= `MODE_SHIFT;
            shifting_row <= remove_row_y;

            // score <= score + shifting_row;

            // score_4 <= score/1000;
            // score_3 <= (score/100-(score/1000)*10);
            // score_2 <= (score/10 - (score/100)*10);
            // score_1 <= (score - (score/10)*10);

            // Increment the score
            if (score_1 == 9) begin
                if (score_2 == 9) begin
                    if (score_3 == 9) begin
                        if (score_4 != 9) begin
                            score_4 <= score_4 + 1;
                            score_3 <= 0;
                            score_2 <= 0;
                            score_1 <= 0;
                        end
                    end else begin
                        score_3 <= score_3 + 1;
                        score_2 <= 0;
                        score_1 <= 0;
                    end
                end else begin
                    score_2 <= score_2 + 1;
                    score_1 <= 0;
                end
            end else begin
                score_1 <= score_1 + 1;
            end
        end
    endtask

    // Initialize any registers we need
    initial begin
        mode = `MODE_IDLE;
        fallen_pieces = 0;
        cur_piece = `EMPTY_BLOCK;
        cur_pos_x = 0;
        cur_pos_y = 0;
        cur_rot = 0;
        score_1 = 0;
        score_2 = 0;
        score_3 = 0;
        score_4 = 0;
        score = 0;
    end

    // Starts a new game after a button is pressed in the MODE_IDLE state
    task start_game;
        begin
            mode <= `MODE_PLAY;
            fallen_pieces <= 0;
            score<=0;
            score_1 <= 0;
            score_2 <= 0;
            score_3 <= 0;
            score_4 <= 0;
            get_new_block();
        end
    endtask

    // Determine if the game is over because the current position
    // intersects with a fallen block
    wire game_over = cur_pos_y == 0 && intersects_fallen_pieces(cur_blk_1, cur_blk_2, cur_blk_3, cur_blk_4);








    // Main game logic
    always @ (posedge clkDiv2) begin
        if (drop_timer < `DROP_TIMER_MAX) begin
            drop_timer <= drop_timer + 1;
        end
        game_clk_rst <= 0;

        if (mode == `MODE_IDLE && (start_1pulse)) begin
            start_game();
        end
        
        else if (mode == `MODE_OVER && (start_1pulse)) begin
            mode = `MODE_IDLE;
        end
        
        else if (rst_1pulse) begin
            mode <= `MODE_IDLE;
            add_to_fallen_pieces();
            cur_piece <= `EMPTY_BLOCK;
        end
        
        else if (game_over) begin
            mode <= `MODE_OVER;
            add_to_fallen_pieces();
            cur_piece <= `EMPTY_BLOCK;
        end

        else if ((sw_pause==1) && mode == `MODE_PLAY) begin
            mode <= `MODE_PAUSE;
            old_mode <= mode;
        end
        
        else if ((sw_pause==0) && mode == `MODE_PAUSE) begin
            mode <= old_mode;
        end
        
        else if (mode == `MODE_PLAY) begin
            if (game_clk) begin
                move_down();
                // if(sw_inferno) begin
                //     rotate();
                // end
            end 
            
            else if (remove_row_en) begin
                remove_row();
            end
            //!---------------------------------------------------------------------------------
            else if(been_ready && key_down[last_change]) begin
                if(last_change == 9'b0_0010_1001 && drop_timer == `DROP_TIMER_MAX) begin //space =>down
                    drop_to_bottom();
                end
                else if(last_change==9'b0_0001_1100) begin //A =>left
                    move_left();
                end
                else if(last_change==9'b0_0010_0011) begin  //D => right
                    move_right();
                end
                else if(last_change==9'b0_0001_1101) begin  //W => rotate
                    rotate();
                end
                else if(last_change==9'b0_0001_1011) begin  //S => down
                    move_down();
                end
            end
            //!---------------------------------------------------------------------------------
        end 
        
        else if (mode == `MODE_DROP) begin
            if (game_clk_rst && !sw_pause) begin
                mode <= `MODE_PLAY;
            end 
            else begin
                move_down();
            end
        end
        
        else if (mode == `MODE_SHIFT) begin
            if (shifting_row == 0) begin
                fallen_pieces[0 +: `BLOCKS_WIDE] <= 0;
                if(!sw_inferno) begin
                    mode <= `MODE_PLAY;
                end 
                else begin
                    mode <= `MODE_SUCCESS;
                    add_to_fallen_pieces();
                    cur_piece <= `EMPTY_BLOCK;
                end
            end 
            
            else begin
                fallen_pieces[shifting_row*`BLOCKS_WIDE +: `BLOCKS_WIDE] <= fallen_pieces[(shifting_row - 1)*`BLOCKS_WIDE +: `BLOCKS_WIDE];
                shifting_row <= shifting_row - 1;
            end
        end


        //!-----------------------------------------------------------!//
        else if(mode == `MODE_SUCCESS && start_1pulse) begin
            mode <= `MODE_IDLE;
        end
        //!-----------------------------------------------------------!//
    end

endmodule
