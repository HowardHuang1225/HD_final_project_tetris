`include "definitions.vh"

module seg_display(
    input wire       clk,
    input wire [3:0] score_1, // 1's place
    input wire [3:0] score_2, // 10's place
    input wire [3:0] score_3, // 100's place
    input wire [3:0] score_4, // 1000's place
    output reg [6:0] seg,
    output reg [3:0] an
    );

    // Divide the clock so we get a seg_clk that goes
    // at a couple hundred Hz for displaying the next digit
    reg [17:0] counter;
    reg seg_clk;
    always @ (posedge clk) begin
        if (counter == 50000) begin
            counter <= 0;
            seg_clk <= 1;
        end else begin
            counter <= counter + 1;
            seg_clk <= 0;
        end
    end

    // Which digit we are currently displaying
    reg [1:0] digit;

    initial begin
        digit = 0;
    end

    always @ (posedge seg_clk) begin
        digit <= digit + 1;
        if (digit == 0) begin
            an <= 4'b0111;
            display_digit(score_4);
        end else if (digit == 1) begin
            an <= 4'b1011;
            display_digit(score_3);
        end else if (digit == 2) begin
            an <= 4'b1101;
            display_digit(score_2);
        end else begin
            an <= 4'b1110;
            display_digit(score_1);
        end
    end

    task display_digit;
        input [3:0] d;
        begin
            case (d)
                0: seg <= 7'b1000000;
                1: seg <= 7'b1111001;
                2: seg <= 7'b0100100;
                3: seg <= 7'b0110000;
                4: seg <= 7'b0011001;
                5: seg <= 7'b0010010;
                6: seg <= 7'b0000010;
                7: seg <= 7'b1111000;
                8: seg <= 7'b0000000;
                default: seg <= 7'b0010000;
            endcase
        end
    endtask

endmodule // seg_display
