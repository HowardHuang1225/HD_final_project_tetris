`include "definitions.vh"

module tetris(
    input wire clk,
    input wire btn_drop,
    input wire btn_rotate,
    input wire btn_left,
    input wire btn_right,
    input wire btn_down,
    input wire sw_pause,
    input wire sw_rst,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output wire hsync,
    output wire vsync,
    output wire [6:0] display,
	output wire [3:0] digit
    );


    wire [11:0] rgb;
    assign {vgaRed, vgaGreen, vgaBlue} = rgb;
    //sssss













endmodule