`define silence   32'd50000000

module music(
    input clk,
    input rst,        // BTNC: active high reset
    input _mute,      // SW14: Mute
    input wire [2:0] _mode,      // SW15: Mode
    input _volUP,     // BTNU: Vol up
    input _volDOWN,   // BTND: Vol down
    output audio_mclk, // master clock
    output audio_lrck, // left-right clock
    output audio_sck,  // serial clock
    output audio_sdin // serial audio data input
    );        
    
    

    // Internal Signal
    wire [15:0] audio_in_left, audio_in_right;

    wire [11:0] ibeatNum;               // Beat counter
    wire [31:0] freqL, freqR;           // Raw frequency, produced by music module
    wire [21:0] freq_outL, freq_outR;    // Processed frequency, adapted to the clock rate of Basys3


    // clkDiv22
    wire clkDiv22;
    clock_divider #(.n(22)) clock_22(.clk(clk), .clk_div(clkDiv22));    // for audio


    // debounced
    wire rst_debounced;
    wire volUP_debounced;
    wire volDOWN_debounced;


    debouncer db0 (.enabled(rst_debounced), .raw(rst), .clk(clk));
    debouncer db1 (.enabled(volUP_debounced), .raw(_volUP), .clk(clk));
    debouncer db2 (.enabled(volDOWN_debounced), .raw(_volDOWN), .clk(clk));
    
    // onepulse
    wire rst_1pulse;
    wire volUP_1pulse;
    wire volDOWN_1pulse;
    
    one_pulse op0 (.pb_in(rst_debounced), .clk(clk), .pb_out(rst_1pulse));
    one_pulse op1 (.pb_in(volUP_debounced), .clk(clk), .pb_out(volUP_1pulse));
    one_pulse op2 (.pb_in(volDOWN_debounced), .clk(clk), .pb_out(volDOWN_1pulse));
    

    // volume level
    reg [2:0] vol = 3'd3;
    reg [2:0] nxt_vol;

    always @(posedge clk or posedge rst_1pulse) begin
        if(rst_1pulse) begin
            vol <= 3'd3;
        end
        else begin
            vol <= nxt_vol;
        end
    end

    always @* begin
        nxt_vol = vol;
        if(volUP_1pulse) begin
            if(vol != 3'd5) begin
                nxt_vol = vol + 3'd1;
            end
        end
        else if(volDOWN_1pulse) begin
            if(vol != 3'd1) begin
                nxt_vol = vol - 3'd1;
            end
        end
    end

    


    // Player Control
    // [in]  reset, clock, _play, _slow, _music, and _mode
    // [out] beat number
    player_control #(.LEN(1024)) playerCtrl_00 ( 
        .clk(clkDiv22),
        .reset(rst),
        ._mode(_mode),
        .ibeat(ibeatNum)
    );








    // Music module
    // [in]  beat number and en
    // [out] left & right raw frequency
    my_music_example music_00(
        .ibeatNum(ibeatNum),
        .en(_mode),
        .toneL(freqL),
        .toneR(freqR)
    );

    // freq_outL, freq_outR
    // Note gen makes no sound, if freq_out = 50000000 / `silence = 1
    assign freq_outL = 50000000 / freqL;
    assign freq_outR = 50000000 / freqR;

    // Note generation
    // [in]  processed frequency
    // [out] audio wave signal (using square wave here)
    note_gen noteGen_00(
        .clk(clk), 
        .rst(rst), 
        .volume(_mute ? 3'd0 : vol),
        .note_div_left(freq_outL), 
        .note_div_right(freq_outR), 
        .audio_left(audio_in_left),     // left sound audio
        .audio_right(audio_in_right)    // right sound audio
    );

    // Speaker controller
    speaker_control sc(
        .clk(clk), 
        .rst(rst), 
        .audio_in_left(audio_in_left),      // left channel audio data input
        .audio_in_right(audio_in_right),    // right channel audio data input
        .audio_mclk(audio_mclk),            // master clock
        .audio_lrck(audio_lrck),            // left-right clock
        .audio_sck(audio_sck),              // serial clock
        .audio_sdin(audio_sdin)             // serial audio data input
    );

endmodule



///////////////////////////////////////////


`define lc   32'd131
`define ld   32'd147
`define le   32'd165
`define lf   32'd174
`define lgM  32'd184
`define lg   32'd196
`define la   32'd220
`define lb   32'd247
`define c   32'd262
`define d   32'd294
`define eM  32'd311
`define e   32'd330
`define f   32'd349
`define gM  32'd370
`define g   32'd392
`define a   32'd440
`define b   32'd494
`define hc  32'd524
`define hd  32'd588
`define he  32'd660
`define hf  32'd698
`define hg  32'd784
`define ha  32'd880
`define hb  32'd988

`define sil   32'd50000000 // slience

module my_music_example (
	input [11:0] ibeatNum,
	input wire [2:0] en,
	output reg [31:0] toneL,
    output reg [31:0] toneR
);

    always @* begin
        if(en == 0) begin
            case(ibeatNum)
                // --- Measure 1 ---
                12'd0: toneR = `he;      12'd1: toneR = `he; // HE (one-beat)
                12'd2: toneR = `he;      12'd3: toneR = `he;
                12'd4: toneR = `he;      12'd5: toneR = `he;
                12'd6: toneR = `he;      12'd7: toneR = `he;
                12'd8: toneR = `he;      12'd9: toneR = `he;
                12'd10: toneR = `he;     12'd11: toneR = `he;
                12'd12: toneR = `he;     12'd13: toneR = `he;
                12'd14: toneR = `he;     12'd15: toneR = `he;

                12'd16: toneR = `b;     12'd17: toneR = `b; // B (half-beat)
                12'd18: toneR = `b;     12'd19: toneR = `b;
                12'd20: toneR = `b;     12'd21: toneR = `b;
                12'd22: toneR = `b;     12'd23: toneR = `b;
                12'd24: toneR = `hc;     12'd25: toneR = `hc; // HC (half-beat)
                12'd26: toneR = `hc;     12'd27: toneR = `hc;
                12'd28: toneR = `hc;     12'd29: toneR = `hc;
                12'd30: toneR = `hc;     12'd31: toneR = `hc;

                12'd32: toneR = `hd;     12'd33: toneR = `hd; // HD (one-beat)
                12'd34: toneR = `hd;     12'd35: toneR = `hd;
                12'd36: toneR = `hd;     12'd37: toneR = `hd;
                12'd38: toneR = `hd;     12'd39: toneR = `hd;
                12'd40: toneR = `hd;     12'd41: toneR = `hd;
                12'd42: toneR = `hd;     12'd43: toneR = `hd;
                12'd44: toneR = `hd;     12'd45: toneR = `hd;
                12'd46: toneR = `hd;     12'd47: toneR = `hd;

                12'd48: toneR = `hc;     12'd49: toneR = `hc; // HC (half-beat)
                12'd50: toneR = `hc;     12'd51: toneR = `hc;
                12'd52: toneR = `hc;     12'd53: toneR = `hc;
                12'd54: toneR = `hc;     12'd55: toneR = `hc;
                12'd56: toneR = `b;     12'd57: toneR = `b; // B (half-beat)
                12'd58: toneR = `b;     12'd59: toneR = `b;
                12'd60: toneR = `b;     12'd61: toneR = `b;
                12'd62: toneR = `b;     12'd63: toneR = `b;

                // --- Measure 2 ---
                12'd64: toneR = `a;     12'd65: toneR = `a; // A (one-beat)
                12'd66: toneR = `a;     12'd67: toneR = `a;
                12'd68: toneR = `a;     12'd69: toneR = `a;
                12'd70: toneR = `a;     12'd71: toneR = `a;
                12'd72: toneR = `a;     12'd73: toneR = `a;
                12'd74: toneR = `a;     12'd75: toneR = `a;
                12'd76: toneR = `a;     12'd77: toneR = `a;
                12'd78: toneR = `a;     12'd79: toneR = `sil; // (Short break for repetitive notes: A)

                12'd80: toneR = `a;     12'd81: toneR = `a; // A (half-beat)
                12'd82: toneR = `a;     12'd83: toneR = `a;
                12'd84: toneR = `a;     12'd85: toneR = `a;
                12'd86: toneR = `a;     12'd87: toneR = `a;
                12'd88: toneR = `hc;     12'd89: toneR = `hc; // HC (half-beat)
                12'd90: toneR = `hc;     12'd91: toneR = `hc;
                12'd92: toneR = `hc;     12'd93: toneR = `hc;
                12'd94: toneR = `hc;     12'd95: toneR = `hc;

                12'd96: toneR = `he;     12'd97: toneR = `he; // HE (one-beat)
                12'd98: toneR = `he;     12'd99: toneR = `he;
                12'd100: toneR = `he;    12'd101: toneR = `he;
                12'd102: toneR = `he;    12'd103: toneR = `he;
                12'd106: toneR = `he;    12'd107: toneR = `he;
                12'd108: toneR = `he;    12'd109: toneR = `he;
                12'd110: toneR = `he;    12'd111: toneR = `he; 

                12'd112: toneR = `he;    12'd113: toneR = `he; // HE (half-beat)
                12'd114: toneR = `he;    12'd115: toneR = `he;
                12'd116: toneR = `he;    12'd117: toneR = `he;
                12'd118: toneR = `he;    12'd119: toneR = `he;
                12'd120: toneR = `hc;    12'd121: toneR = `hc; // HC (half-beat)
                12'd122: toneR = `hc;    12'd123: toneR = `hc;
                12'd124: toneR = `hc;    12'd125: toneR = `hc;
                12'd126: toneR = `hc;    12'd127: toneR = `hc;

                                // --- Measure 3 ---
                12'd128: toneR = `b;     12'd129: toneR = `b; // B (one-beat)
                12'd130: toneR = `b;     12'd131: toneR = `b;
                12'd132: toneR = `b;     12'd133: toneR = `b;
                12'd134: toneR = `b;     12'd135: toneR = `b;
                12'd136: toneR = `b;     12'd137: toneR = `b;
                12'd138: toneR = `b;     12'd139: toneR = `b;
                12'd140: toneR = `b;     12'd141: toneR = `b;
                12'd142: toneR = `b;     12'd143: toneR = `sil; // (Short break for repetitive notes: B)

                12'd144: toneR = `b;     12'd145: toneR = `b; // B (half-beat)
                12'd146: toneR = `b;     12'd147: toneR = `b;
                12'd148: toneR = `b;     12'd149: toneR = `b;
                12'd150: toneR = `b;     12'd151: toneR = `b;
                12'd152: toneR = `hc;     12'd153: toneR = `hc; // HC (half-beat)
                12'd154: toneR = `hc;     12'd155: toneR = `hc;
                12'd156: toneR = `hc;     12'd157: toneR = `hc;
                12'd158: toneR = `hc;     12'd159: toneR = `hc;

                12'd160: toneR = `hd;     12'd161: toneR = `hd; // HD (one-beat)
                12'd162: toneR = `hd;     12'd163: toneR = `hd;
                12'd164: toneR = `hd;     12'd165: toneR = `hd;
                12'd166: toneR = `hd;     12'd167: toneR = `hd;
                12'd168: toneR = `hd;     12'd169: toneR = `hd;
                12'd170: toneR = `hd;     12'd171: toneR = `hd;
                12'd172: toneR = `hd;     12'd173: toneR = `hd;
                12'd174: toneR = `hd;     12'd175: toneR = `hd;

                12'd176: toneR = `he;     12'd177: toneR = `he; // HE (one-beat)
                12'd178: toneR = `he;     12'd179: toneR = `he;
                12'd180: toneR = `he;     12'd181: toneR = `he;
                12'd182: toneR = `he;     12'd183: toneR = `he;
                12'd184: toneR = `he;     12'd185: toneR = `he;
                12'd186: toneR = `he;     12'd187: toneR = `he;
                12'd188: toneR = `he;     12'd189: toneR = `he;
                12'd190: toneR = `he;     12'd191: toneR = `he;

                                // --- Measure 4 ---
                12'd192: toneR = `hc;     12'd193: toneR = `hc; // HC (one-beat)
                12'd194: toneR = `hc;     12'd195: toneR = `hc;
                12'd196: toneR = `hc;     12'd197: toneR = `hc;
                12'd198: toneR = `hc;     12'd199: toneR = `hc;
                12'd200: toneR = `hc;     12'd201: toneR = `hc;
                12'd202: toneR = `hc;     12'd203: toneR = `hc;
                12'd204: toneR = `hc;     12'd205: toneR = `hc;
                12'd206: toneR = `hc;     12'd207: toneR = `hc;

                12'd208: toneR = `a;     12'd209: toneR = `a; // A (one-beat)
                12'd210: toneR = `a;     12'd211: toneR = `a;
                12'd212: toneR = `a;     12'd213: toneR = `a;
                12'd214: toneR = `a;     12'd215: toneR = `a;
                12'd216: toneR = `a;     12'd217: toneR = `a;
                12'd218: toneR = `a;     12'd219: toneR = `a;
                12'd220: toneR = `a;     12'd221: toneR = `a;
                12'd222: toneR = `a;     12'd223: toneR = `sil; // (Short break for repetitive notes: A)

                12'd224: toneR = `a;     12'd225: toneR = `a; // A (one-beat)
                12'd226: toneR = `a;     12'd227: toneR = `a;
                12'd228: toneR = `a;     12'd229: toneR = `a;
                12'd230: toneR = `a;     12'd231: toneR = `a;
                12'd232: toneR = `a;     12'd233: toneR = `a;
                12'd234: toneR = `a;     12'd235: toneR = `a;
                12'd236: toneR = `a;     12'd237: toneR = `a;
                12'd238: toneR = `a;     12'd239: toneR = `a;

                12'd240: toneR = `sil;     12'd241: toneR = `sil; // Silence (one-beat)
                12'd242: toneR = `sil;     12'd243: toneR = `sil;
                12'd244: toneR = `sil;     12'd245: toneR = `sil;
                12'd246: toneR = `sil;     12'd247: toneR = `sil;
                12'd248: toneR = `sil;     12'd249: toneR = `sil;
                12'd250: toneR = `sil;     12'd251: toneR = `sil;
                12'd252: toneR = `sil;     12'd253: toneR = `sil;
                12'd254: toneR = `sil;     12'd255: toneR = `sil;

                                // --- Measure 5 ---
                12'd256: toneR = `sil;     12'd257: toneR = `sil; // Silencd (half-beat)
                12'd258: toneR = `sil;     12'd259: toneR = `sil;
                12'd260: toneR = `sil;     12'd261: toneR = `sil;
                12'd262: toneR = `sil;     12'd263: toneR = `sil;
                12'd264: toneR = `hd;     12'd265: toneR = `hd; // HD (half-beat)
                12'd266: toneR = `hd;     12'd267: toneR = `hd;
                12'd268: toneR = `hd;     12'd269: toneR = `hd;
                12'd270: toneR = `hd;     12'd271: toneR = `hd;

                12'd272: toneR = `hd;     12'd273: toneR = `hd; // HD (half-beat)
                12'd274: toneR = `hd;     12'd275: toneR = `hd;
                12'd276: toneR = `hd;     12'd277: toneR = `hd;
                12'd278: toneR = `hd;     12'd279: toneR = `hd;
                12'd280: toneR = `hf;     12'd281: toneR = `hf; // HF half-beat)
                12'd282: toneR = `hf;     12'd283: toneR = `hf;
                12'd284: toneR = `hf;     12'd285: toneR = `hf;
                12'd286: toneR = `hf;     12'd287: toneR = `hf;

                12'd288: toneR = `ha;     12'd289: toneR = `ha; // HA (one-beat)
                12'd290: toneR = `ha;     12'd291: toneR = `ha;
                12'd292: toneR = `ha;     12'd293: toneR = `ha;
                12'd294: toneR = `ha;     12'd295: toneR = `ha; 
                12'd296: toneR = `ha;     12'd297: toneR = `ha;
                12'd298: toneR = `ha;     12'd299: toneR = `ha;
                12'd300: toneR = `ha;     12'd301: toneR = `ha;
                12'd302: toneR = `ha;     12'd303: toneR = `ha;

                12'd304: toneR = `hg;     12'd305: toneR = `hg; // HG (half-beat)
                12'd306: toneR = `hg;     12'd307: toneR = `hg;
                12'd308: toneR = `hg;     12'd309: toneR = `hg;
                12'd310: toneR = `hg;     12'd311: toneR = `hg;
                12'd312: toneR = `hf;     12'd313: toneR = `hf; // HD (half-beat)
                12'd314: toneR = `hf;     12'd315: toneR = `hf;
                12'd316: toneR = `hf;     12'd317: toneR = `hf;
                12'd318: toneR = `hf;     12'd319: toneR = `hf; 

                                // --- Measure 6 ---
                12'd320: toneR = `he;     12'd321: toneR = `he; // HE (one-beat)
                12'd322: toneR = `he;     12'd323: toneR = `he;
                12'd324: toneR = `he;     12'd325: toneR = `he;
                12'd326: toneR = `he;     12'd327: toneR = `he;
                12'd328: toneR = `he;     12'd329: toneR = `he;
                12'd330: toneR = `he;     12'd331: toneR = `he;
                12'd332: toneR = `he;     12'd333: toneR = `he;
                12'd334: toneR = `he;     12'd335: toneR = `he;

                12'd336: toneR = `he;     12'd337: toneR = `he; // HE (half-beat)
                12'd338: toneR = `he;     12'd339: toneR = `he;
                12'd340: toneR = `he;     12'd341: toneR = `he;
                12'd342: toneR = `he;     12'd343: toneR = `he;
                12'd344: toneR = `hc;     12'd345: toneR = `hc; // HC half-beat)
                12'd346: toneR = `hc;     12'd347: toneR = `hc;
                12'd348: toneR = `hc;     12'd349: toneR = `hc;
                12'd350: toneR = `hc;     12'd351: toneR = `hc;

                12'd352: toneR = `he;     12'd353: toneR = `he; // HE (one-beat)
                12'd354: toneR = `he;     12'd355: toneR = `he;
                12'd356: toneR = `he;     12'd357: toneR = `he;
                12'd358: toneR = `he;     12'd359: toneR = `he; 
                12'd360: toneR = `he;     12'd361: toneR = `he;
                12'd362: toneR = `he;     12'd363: toneR = `he;
                12'd364: toneR = `he;     12'd365: toneR = `he;
                12'd366: toneR = `he;     12'd367: toneR = `he;

                12'd368: toneR = `hd;     12'd369: toneR = `hd; // HD (half-beat)
                12'd370: toneR = `hd;     12'd371: toneR = `hd;
                12'd372: toneR = `hd;     12'd373: toneR = `hd;
                12'd374: toneR = `hd;     12'd375: toneR = `hd;
                12'd376: toneR = `hd;     12'd377: toneR = `hc; // HC (half-beat)
                12'd378: toneR = `hd;     12'd379: toneR = `hc;
                12'd380: toneR = `hc;     12'd381: toneR = `hc;
                12'd382: toneR = `hc;     12'd383: toneR = `hc;

                                // --- Measure 7 ---
                12'd384: toneR = `b;     12'd385: toneR = `b; // B (one-beat)
                12'd386: toneR = `b;     12'd387: toneR = `b;
                12'd388: toneR = `b;     12'd389: toneR = `b;
                12'd390: toneR = `b;     12'd391: toneR = `b;
                12'd392: toneR = `b;     12'd393: toneR = `b;
                12'd394: toneR = `b;     12'd395: toneR = `b;
                12'd396: toneR = `b;     12'd397: toneR = `b;
                12'd398: toneR = `b;     12'd399: toneR = `sil; // (Short break for repetitive notes: B)

                12'd400: toneR = `b;     12'd401: toneR = `b; // b (half-beat)
                12'd402: toneR = `b;     12'd403: toneR = `b;
                12'd404: toneR = `b;     12'd405: toneR = `b;
                12'd406: toneR = `b;     12'd407: toneR = `b;
                12'd408: toneR = `hc;     12'd409: toneR = `hc; // hc (half-beat)
                12'd410: toneR = `hc;     12'd411: toneR = `hc;
                12'd412: toneR = `hc;     12'd413: toneR = `hc;
                12'd414: toneR = `hc;     12'd415: toneR = `hc;

                12'd416: toneR = `hd;     12'd417: toneR = `hd; // HD (one-beat)
                12'd418: toneR = `hd;     12'd419: toneR = `hd;
                12'd420: toneR = `hd;     12'd421: toneR = `hd;
                12'd422: toneR = `hd;     12'd423: toneR = `hd;
                12'd424: toneR = `hd;     12'd425: toneR = `hd;
                12'd426: toneR = `hd;     12'd427: toneR = `hd;
                12'd428: toneR = `hd;     12'd429: toneR = `hd;
                12'd430: toneR = `hd;     12'd431: toneR = `hd;

                12'd432: toneR = `he;     12'd433: toneR = `he; // HE (one-beat)
                12'd434: toneR = `he;     12'd435: toneR = `he;
                12'd436: toneR = `he;     12'd437: toneR = `he;
                12'd438: toneR = `he;     12'd439: toneR = `he;
                12'd440: toneR = `he;     12'd441: toneR = `he;
                12'd442: toneR = `he;     12'd443: toneR = `he;
                12'd444: toneR = `he;     12'd445: toneR = `he;
                12'd446: toneR = `he;     12'd447: toneR = `he;

                                // --- Measure 8 ---
                12'd448: toneR = `hc;     12'd449: toneR = `hc; // HC (one-beat)
                12'd450: toneR = `hc;     12'd451: toneR = `hc;
                12'd452: toneR = `hc;     12'd453: toneR = `hc;
                12'd454: toneR = `hc;     12'd455: toneR = `hc;
                12'd456: toneR = `hc;     12'd457: toneR = `hc;
                12'd458: toneR = `hc;     12'd459: toneR = `hc;
                12'd460: toneR = `hc;     12'd461: toneR = `hc;
                12'd462: toneR = `hc;     12'd463: toneR = `hc;

                12'd464: toneR = `a;     12'd465: toneR = `a; // A (one-beat)
                12'd466: toneR = `a;     12'd467: toneR = `a;
                12'd468: toneR = `a;     12'd469: toneR = `a;
                12'd470: toneR = `a;     12'd471: toneR = `a;
                12'd472: toneR = `a;     12'd473: toneR = `a;
                12'd474: toneR = `a;     12'd475: toneR = `a;
                12'd476: toneR = `a;     12'd477: toneR = `a;
                12'd478: toneR = `a;     12'd479: toneR = `sil; // (Short break for repetitive notes: A)

                12'd480: toneR = `a;     12'd481: toneR = `a; // A (one-beat)
                12'd482: toneR = `a;     12'd483: toneR = `a;
                12'd484: toneR = `a;     12'd485: toneR = `a;
                12'd486: toneR = `a;     12'd487: toneR = `a;
                12'd488: toneR = `a;     12'd489: toneR = `a;
                12'd490: toneR = `a;     12'd491: toneR = `a;
                12'd492: toneR = `a;     12'd493: toneR = `a;
                12'd494: toneR = `a;     12'd495: toneR = `a;

                12'd496: toneR = `sil;     12'd497: toneR = `sil; // Silence (one-beat)
                12'd498: toneR = `sil;     12'd499: toneR = `sil;
                12'd500: toneR = `sil;     12'd501: toneR = `sil;
                12'd502: toneR = `sil;     12'd503: toneR = `sil;
                12'd504: toneR = `sil;     12'd505: toneR = `sil;
                12'd506: toneR = `sil;     12'd507: toneR = `sil;
                12'd508: toneR = `sil;     12'd509: toneR = `sil;
                12'd510: toneR = `sil;     12'd511: toneR = `sil;

                                // --- Measure 9 ---
                12'd512: toneR = `e;     12'd513: toneR = `e; // E (two-beat)
                12'd514: toneR = `e;     12'd515: toneR = `e;
                12'd516: toneR = `e;     12'd517: toneR = `e;
                12'd518: toneR = `e;     12'd519: toneR = `e;
                12'd520: toneR = `e;     12'd521: toneR = `e;
                12'd522: toneR = `e;     12'd523: toneR = `e;
                12'd524: toneR = `e;     12'd525: toneR = `e;
                12'd526: toneR = `e;     12'd527: toneR = `e;

                12'd528: toneR = `e;     12'd529: toneR = `e;
                12'd530: toneR = `e;     12'd531: toneR = `e;
                12'd532: toneR = `e;     12'd533: toneR = `e;
                12'd534: toneR = `e;     12'd535: toneR = `e;
                12'd536: toneR = `e;     12'd537: toneR = `e;
                12'd538: toneR = `e;     12'd539: toneR = `e;
                12'd540: toneR = `e;     12'd541: toneR = `e;
                12'd542: toneR = `e;     12'd543: toneR = `e;

                12'd544: toneR = `c;     12'd545: toneR = `c; // C (two-beat)
                12'd546: toneR = `c;     12'd547: toneR = `c;
                12'd548: toneR = `c;     12'd549: toneR = `c;
                12'd550: toneR = `c;     12'd551: toneR = `c;
                12'd552: toneR = `c;     12'd553: toneR = `c;
                12'd554: toneR = `c;     12'd555: toneR = `c;
                12'd556: toneR = `c;     12'd557: toneR = `c;
                
                12'd558: toneR = `c;     12'd559: toneR = `c;
                12'd560: toneR = `c;     12'd561: toneR = `c;
                12'd562: toneR = `c;     12'd563: toneR = `c;
                12'd564: toneR = `c;     12'd565: toneR = `c;
                12'd566: toneR = `c;     12'd567: toneR = `c;
                12'd568: toneR = `c;     12'd569: toneR = `c;
                12'd570: toneR = `c;     12'd571: toneR = `c;
                12'd572: toneR = `c;     12'd573: toneR = `c;
                12'd574: toneR = `c;     12'd575: toneR = `c;

                                // --- Measure 10 ---
                12'd576: toneR = `d;     12'd577: toneR = `d; // D (two-beat)
                12'd578: toneR = `d;     12'd579: toneR = `d;
                12'd580: toneR = `d;     12'd581: toneR = `d;
                12'd582: toneR = `d;     12'd583: toneR = `d;
                12'd584: toneR = `d;     12'd585: toneR = `d;
                12'd586: toneR = `d;     12'd587: toneR = `d;
                12'd588: toneR = `d;     12'd589: toneR = `d;
                12'd590: toneR = `d;     12'd591: toneR = `d;

                12'd592: toneR = `d;     12'd593: toneR = `d;
                12'd594: toneR = `d;     12'd595: toneR = `d;
                12'd596: toneR = `d;     12'd597: toneR = `d;
                12'd598: toneR = `d;     12'd599: toneR = `d;
                12'd600: toneR = `d;     12'd601: toneR = `d;
                12'd602: toneR = `d;     12'd603: toneR = `d;
                12'd604: toneR = `d;     12'd605: toneR = `d;
                12'd606: toneR = `d;     12'd607: toneR = `d;
                
                12'd608: toneR = `lb;     12'd609: toneR = `lb; //LB (two-beat)
                12'd610: toneR = `lb;     12'd611: toneR = `lb;
                12'd612: toneR = `lb;     12'd613: toneR = `lb;
                12'd614: toneR = `lb;     12'd615: toneR = `lb;
                12'd616: toneR = `lb;     12'd617: toneR = `lb;
                12'd618: toneR = `lb;     12'd619: toneR = `lb;
                12'd620: toneR = `lb;     12'd621: toneR = `lb;
                12'd622: toneR = `lb;     12'd623: toneR = `lb;

                12'd624: toneR = `lb;     12'd625: toneR = `lb;
                12'd626: toneR = `lb;     12'd627: toneR = `lb;
                12'd628: toneR = `lb;     12'd629: toneR = `lb;
                12'd630: toneR = `lb;     12'd631: toneR = `lb;
                12'd632: toneR = `lb;     12'd633: toneR = `lb;
                12'd634: toneR = `lb;     12'd635: toneR = `lb;
                12'd636: toneR = `lb;     12'd637: toneR = `lb;
                12'd638: toneR = `lb;     12'd639: toneR = `lb;
                
                                // --- Measure 11 ---
                12'd640: toneR = `c;     12'd641: toneR = `c; // C (two-beat)
                12'd642: toneR = `c;     12'd643: toneR = `c;
                12'd644: toneR = `c;     12'd645: toneR = `c;
                12'd646: toneR = `c;     12'd647: toneR = `c;
                12'd648: toneR = `c;     12'd649: toneR = `c;
                12'd650: toneR = `c;     12'd651: toneR = `c;
                12'd652: toneR = `c;     12'd653: toneR = `c;
                12'd654: toneR = `c;     12'd655: toneR = `c;

                12'd656: toneR = `c;     12'd657: toneR = `c;
                12'd658: toneR = `c;     12'd659: toneR = `c;
                12'd660: toneR = `c;     12'd661: toneR = `c;
                12'd662: toneR = `c;     12'd663: toneR = `c;
                12'd664: toneR = `c;     12'd665: toneR = `c;
                12'd666: toneR = `c;     12'd667: toneR = `c;
                12'd668: toneR = `c;     12'd669: toneR = `c;
                12'd670: toneR = `c;     12'd671: toneR = `c;

                12'd672: toneR = `la;     12'd673: toneR = `la; // LA (two-beat)
                12'd674: toneR = `la;     12'd675: toneR = `la;
                12'd676: toneR = `la;     12'd677: toneR = `la;
                12'd678: toneR = `la;     12'd679: toneR = `la;
                12'd680: toneR = `la;     12'd681: toneR = `la;
                12'd682: toneR = `la;     12'd683: toneR = `la;
                12'd684: toneR = `la;     12'd685: toneR = `la;
                12'd686: toneR = `la;     12'd687: toneR = `la;

                12'd688: toneR = `la;     12'd689: toneR = `la;
                12'd690: toneR = `la;     12'd691: toneR = `la;
                12'd692: toneR = `la;     12'd693: toneR = `la;
                12'd694: toneR = `la;     12'd695: toneR = `la;
                12'd696: toneR = `la;     12'd697: toneR = `la;
                12'd698: toneR = `la;     12'd699: toneR = `la;
                12'd700: toneR = `la;     12'd701: toneR = `la;
                12'd702: toneR = `la;     12'd703: toneR = `la;

                                // --- Measure 12 ---
                12'd704: toneR = 184;     12'd705: toneR = 184; // LG# (two-beat)
                12'd706: toneR = 184;     12'd707: toneR = 184;
                12'd708: toneR = 184;     12'd709: toneR = 184;
                12'd710: toneR = 184;     12'd711: toneR = 184;
                12'd712: toneR = 184;     12'd713: toneR = 184;
                12'd714: toneR = 184;     12'd715: toneR = 184;
                12'd716: toneR = 184;     12'd717: toneR = 184;
                12'd718: toneR = 184;     12'd719: toneR = 184;

                12'd720: toneR = 184;     12'd721: toneR = 184;
                12'd722: toneR = 184;     12'd723: toneR = 184;
                12'd724: toneR = 184;     12'd725: toneR = 184;
                12'd726: toneR = 184;     12'd727: toneR = 184;
                12'd728: toneR = 184;     12'd729: toneR = 184;
                12'd730: toneR = 184;     12'd731: toneR = 184;
                12'd732: toneR = 184;     12'd733: toneR = 184;
                12'd734: toneR = 184;     12'd735: toneR = 184;
                
                12'd736: toneR = `lb;     12'd737: toneR = `lb; // LB (two-beat)
                12'd738: toneR = `lb;     12'd739: toneR = `lb;
                12'd740: toneR = `lb;     12'd741: toneR = `lb;
                12'd742: toneR = `lb;     12'd743: toneR = `lb;
                12'd744: toneR = `lb;     12'd745: toneR = `lb;
                12'd746: toneR = `lb;     12'd747: toneR = `lb;
                12'd748: toneR = `lb;     12'd749: toneR = `lb;
                12'd750: toneR = `lb;     12'd751: toneR = `lb;

                12'd752: toneR = `lb;     12'd753: toneR = `lb;
                12'd754: toneR = `lb;     12'd755: toneR = `lb;
                12'd756: toneR = `lb;     12'd757: toneR = `lb;
                12'd758: toneR = `lb;     12'd759: toneR = `lb;
                12'd760: toneR = `lb;     12'd761: toneR = `lb;
                12'd762: toneR = `lb;     12'd763: toneR = `lb;
                12'd764: toneR = `lb;     12'd765: toneR = `lb;
                12'd766: toneR = `lb;     12'd767: toneR = `lb;

                                // --- Measure 13 ---
                12'd768: toneR = `e;     12'd769: toneR = `e; // E (two-beat)
                12'd770: toneR = `e;     12'd771: toneR = `e;
                12'd772: toneR = `e;     12'd773: toneR = `e;
                12'd774: toneR = `e;     12'd775: toneR = `e;
                12'd776: toneR = `e;     12'd777: toneR = `e;
                12'd778: toneR = `e;     12'd779: toneR = `e;
                12'd780: toneR = `e;     12'd781: toneR = `e;
                12'd782: toneR = `e;     12'd783: toneR = `e;

                12'd784: toneR = `e;     12'd785: toneR = `e;
                12'd786: toneR = `e;     12'd787: toneR = `e;
                12'd788: toneR = `e;     12'd789: toneR = `e;
                12'd790: toneR = `e;     12'd791: toneR = `e;
                12'd792: toneR = `e;     12'd793: toneR = `e;
                12'd794: toneR = `e;     12'd795: toneR = `e;
                12'd796: toneR = `e;     12'd797: toneR = `e;
                12'd798: toneR = `e;     12'd799: toneR = `e;

                12'd800: toneR = `c;     12'd801: toneR = `c; // C (two-beat)
                12'd802: toneR = `c;     12'd803: toneR = `c;
                12'd804: toneR = `c;     12'd805: toneR = `c;
                12'd806: toneR = `c;     12'd807: toneR = `c;
                12'd808: toneR = `c;     12'd809: toneR = `c;
                12'd810: toneR = `c;     12'd811: toneR = `c;
                12'd812: toneR = `c;     12'd813: toneR = `c;
                12'd814: toneR = `c;     12'd815: toneR = `c;

                12'd816: toneR = `c;     12'd817: toneR = `c;
                12'd818: toneR = `c;     12'd819: toneR = `c;
                12'd820: toneR = `c;     12'd821: toneR = `c;
                12'd822: toneR = `c;     12'd823: toneR = `c;
                12'd824: toneR = `c;     12'd825: toneR = `c;
                12'd826: toneR = `c;     12'd827: toneR = `c;
                12'd828: toneR = `c;     12'd829: toneR = `c;
                12'd830: toneR = `c;     12'd831: toneR = `c;

                                // --- Measure 14 ---
                12'd832: toneR = `d;     12'd833: toneR = `d; // D (two-beat)
                12'd834: toneR = `d;     12'd835: toneR = `d;
                12'd836: toneR = `d;     12'd837: toneR = `d;
                12'd838: toneR = `d;     12'd839: toneR = `d;
                12'd840: toneR = `d;     12'd841: toneR = `d;
                12'd842: toneR = `d;     12'd843: toneR = `d;
                12'd844: toneR = `d;     12'd845: toneR = `d;
                12'd846: toneR = `d;     12'd847: toneR = `d;

                12'd848: toneR = `d;     12'd849: toneR = `d;
                12'd850: toneR = `d;     12'd851: toneR = `d;
                12'd852: toneR = `d;     12'd853: toneR = `d;
                12'd854: toneR = `d;     12'd855: toneR = `d;
                12'd856: toneR = `d;     12'd857: toneR = `d;
                12'd858: toneR = `d;     12'd859: toneR = `d;
                12'd860: toneR = `d;     12'd861: toneR = `d;
                12'd862: toneR = `d;     12'd863: toneR = `d;

                12'd864: toneR = `lb;     12'd865: toneR = `lb; // LB (two-beat)
                12'd866: toneR = `lb;     12'd867: toneR = `lb;
                12'd868: toneR = `lb;     12'd869: toneR = `lb;
                12'd870: toneR = `lb;     12'd871: toneR = `lb;
                12'd872: toneR = `lb;     12'd873: toneR = `lb;
                12'd874: toneR = `lb;     12'd875: toneR = `lb;
                12'd876: toneR = `lb;     12'd877: toneR = `lb;
                12'd878: toneR = `lb;     12'd879: toneR = `lb;

                12'd880: toneR = `lb;     12'd881: toneR = `lb;
                12'd882: toneR = `lb;     12'd883: toneR = `lb;
                12'd884: toneR = `lb;     12'd885: toneR = `lb;
                12'd886: toneR = `lb;     12'd887: toneR = `lb;
                12'd888: toneR = `lb;     12'd889: toneR = `lb;
                12'd890: toneR = `lb;     12'd891: toneR = `lb;
                12'd892: toneR = `lb;     12'd893: toneR = `lb;
                12'd894: toneR = `lb;     12'd895: toneR = `lb;

                                // --- Measure 15 ---
                12'd896: toneR = `c;     12'd897: toneR = `c; // C (one-beat)
                12'd898: toneR = `c;     12'd899: toneR = `c;
                12'd900: toneR = `c;     12'd901: toneR = `c;
                12'd902: toneR = `c;     12'd903: toneR = `c;
                12'd904: toneR = `c;     12'd905: toneR = `c;
                12'd906: toneR = `c;     12'd907: toneR = `c;
                12'd908: toneR = `c;     12'd909: toneR = `c;
                12'd910: toneR = `c;     12'd911: toneR = `c;

                12'd912: toneR = `e;     12'd913: toneR = `e; // E (one-beat)
                12'd914: toneR = `e;     12'd915: toneR = `e;
                12'd916: toneR = `e;     12'd917: toneR = `e;
                12'd918: toneR = `e;     12'd919: toneR = `e;
                12'd920: toneR = `e;     12'd921: toneR = `e;
                12'd922: toneR = `e;     12'd923: toneR = `e;
                12'd924: toneR = `e;     12'd925: toneR = `e;
                12'd926: toneR = `e;     12'd927: toneR = `e;
                12'd928: toneR = `a;     12'd929: toneR = `a;

                12'd930: toneR = `a;     12'd931: toneR = `a; // A (oen-beat)
                12'd932: toneR = `a;     12'd933: toneR = `a;
                12'd934: toneR = `a;     12'd935: toneR = `a;
                12'd936: toneR = `a;     12'd937: toneR = `a;
                12'd938: toneR = `a;     12'd939: toneR = `a;
                12'd940: toneR = `a;     12'd941: toneR = `a;
                12'd942: toneR = `a;     12'd943: toneR = `a;
                12'd944: toneR = `a;     12'd945: toneR = `sil;

                12'd946: toneR = `a;     12'd947: toneR = `a; // A (one-beat)
                12'd948: toneR = `a;     12'd949: toneR = `a;
                12'd950: toneR = `a;     12'd951: toneR = `a;
                12'd952: toneR = `a;     12'd953: toneR = `a;
                12'd954: toneR = `a;     12'd955: toneR = `a;
                12'd956: toneR = `a;     12'd957: toneR = `a;
                12'd958: toneR = `a;     12'd959: toneR = `a;

                                // --- Measure 16 ---
                12'd960: toneR = 370;     12'd961: toneR = 370; // G# (four-beat)
                12'd962: toneR = 370;     12'd963: toneR = 370;
                12'd964: toneR = 370;     12'd965: toneR = 370;
                12'd966: toneR = 370;     12'd967: toneR = 370;
                12'd968: toneR = 370;     12'd969: toneR = 370;
                12'd970: toneR = 370;     12'd971: toneR = 370;
                12'd972: toneR = 370;     12'd973: toneR = 370;
                12'd974: toneR = 370;     12'd975: toneR = 370;

                12'd976: toneR = 370;     12'd977: toneR = 370;
                12'd978: toneR = 370;     12'd979: toneR = 370;
                12'd980: toneR = 370;     12'd981: toneR = 370;
                12'd982: toneR = 370;     12'd983: toneR = 370;
                12'd984: toneR = 370;     12'd985: toneR = 370;
                12'd986: toneR = 370;     12'd987: toneR = 370;
                12'd988: toneR = 370;     12'd989: toneR = 370;
                12'd990: toneR = 370;     12'd991: toneR = 370;

                12'd992: toneR = 370;     12'd993: toneR = 370;
                12'd994: toneR = 370;     12'd995: toneR = 370;
                12'd996: toneR = 370;     12'd997: toneR = 370;
                12'd998: toneR = 370;     12'd999: toneR = 370;
                12'd1000: toneR = 370;     12'd1001: toneR = 370;
                12'd1002: toneR = 370;     12'd1003: toneR = 370;
                12'd1004: toneR = 370;     12'd1005: toneR = 370;
                12'd1006: toneR = 370;     12'd1007: toneR = 370;

                12'd1008: toneR = 370;     12'd1009: toneR = 370;
                12'd1010: toneR = 370;     12'd1011: toneR = 370;
                12'd1012: toneR = 370;     12'd1013: toneR = 370;
                12'd1014: toneR = 370;     12'd1015: toneR = 370;
                12'd1016: toneR = 370;     12'd1017: toneR = 370;
                12'd1018: toneR = 370;     12'd1019: toneR = 370;
                12'd1020: toneR = 370;     12'd1021: toneR = 370;
                12'd1022: toneR = 370;     12'd1023: toneR = 370;

                default: toneR = `sil;
            endcase

        end else begin
            toneR = `sil;
        end
    end

    always @(*) begin
        if(en == 0)begin
            case(ibeatNum)
                                // --- Measure 1 ---
                12'd0: toneL = `eM;     12'd1: toneL = `eM;
                12'd2: toneL = `eM;     12'd3: toneL = `eM;
                12'd4: toneL = `eM;     12'd5: toneL = `eM;
                12'd6: toneL = `eM;     12'd7: toneL = `eM;
                12'd8: toneL = `b;     12'd9: toneL = `hc;
                12'd10: toneL = `b;     12'd11: toneL = `hc;
                12'd12: toneL = `b;     12'd13: toneL = `hc;
                12'd14: toneL = `b;     12'd15: toneL = `hc;

                12'd16: toneL = `e;     12'd17: toneL = `e;
                12'd18: toneL = `e;     12'd19: toneL = `e;
                12'd20: toneL = `e;     12'd21: toneL = `e;
                12'd22: toneL = `e;     12'd23: toneL = `e;
                12'd24: toneL = `b;     12'd25: toneL = `hc;
                12'd26: toneL = `b;     12'd27: toneL = `hc;
                12'd28: toneL = `b;     12'd29: toneL = `hc;
                12'd30: toneL = `b;     12'd31: toneL = `hc;

                12'd32: toneL = `e;     12'd33: toneL = `e;
                12'd34: toneL = `e;     12'd35: toneL = `e;
                12'd36: toneL = `e;     12'd37: toneL = `e;
                12'd38: toneL = `e;     12'd39: toneL = `e;
                12'd40: toneL = `b;     12'd41: toneL = `hc;
                12'd42: toneL = `b;     12'd43: toneL = `hc;
                12'd44: toneL = `b;     12'd45: toneL = `hc;
                12'd46: toneL = `b;     12'd47: toneL = `hc;

                12'd48: toneL = `e;     12'd49: toneL = `e;
                12'd50: toneL = `e;     12'd51: toneL = `e;
                12'd52: toneL = `e;     12'd53: toneL = `e;
                12'd54: toneL = `e;     12'd55: toneL = `e;
                12'd56: toneL = `b;     12'd57: toneL = `hc;
                12'd58: toneL = `b;     12'd59: toneL = `hc;
                12'd60: toneL = `b;     12'd61: toneL = `hc;
                12'd62: toneL = `b;     12'd63: toneL = `hc;

                                // --- Measure 2 ---
                12'd64: toneL = `f;     12'd65: toneL = `f;
                12'd66: toneL = `f;     12'd67: toneL = `f;
                12'd68: toneL = `f;     12'd69: toneL = `f;
                12'd70: toneL = `f;     12'd71: toneL = `f;
                12'd72: toneL = `a;     12'd73: toneL = `hc;
                12'd74: toneL = `a;     12'd75: toneL = `hc;
                12'd76: toneL = `a;     12'd77: toneL = `hc;
                12'd78: toneL = `a;     12'd79: toneL = `hc;

                12'd80: toneL = `f;     12'd81: toneL = `f;
                12'd82: toneL = `f;     12'd83: toneL = `f;
                12'd84: toneL = `f;     12'd85: toneL = `f;
                12'd86: toneL = `f;     12'd87: toneL = `f;
                12'd88: toneL = `a;     12'd89: toneL = `hc;
                12'd90: toneL = `a;     12'd91: toneL = `hc;
                12'd92: toneL = `a;     12'd93: toneL = `hc;
                12'd94: toneL = `a;     12'd95: toneL = `hc;

                12'd96: toneL = `f;     12'd97: toneL = `f;
                12'd98: toneL = `f;     12'd99: toneL = `f;
                12'd100: toneL = `f;     12'd101: toneL = `f;
                12'd102: toneL = `f;     12'd103: toneL = `f;
                12'd104: toneL = `a;     12'd105: toneL = `hc;
                12'd106: toneL = `a;     12'd107: toneL = `hc;
                12'd108: toneL = `a;     12'd109: toneL = `hc;
                12'd110: toneL = `a;     12'd111: toneL = `hc;

                12'd112: toneL = `f;     12'd113: toneL = `f;
                12'd114: toneL = `f;     12'd115: toneL = `f;
                12'd116: toneL = `f;     12'd117: toneL = `f;
                12'd118: toneL = `f;     12'd119: toneL = `f;
                12'd120: toneL = `a;     12'd121: toneL = `hc;
                12'd122: toneL = `a;     12'd123: toneL = `hc;
                12'd124: toneL = `a;     12'd125: toneL = `hc;
                12'd126: toneL = `a;     12'd127: toneL = `hc;

                                // --- Measure 3 ---
                                // --- Measure 3 ---
                12'd128: toneL = `eM;     12'd129: toneL = `eM;
                12'd130: toneL = `eM;     12'd131: toneL = `eM;
                12'd132: toneL = `eM;     12'd133: toneL = `eM;
                12'd134: toneL = `eM;     12'd135: toneL = `eM;
                12'd136: toneL = `b;     12'd137: toneL = `hc;
                12'd138: toneL = `b;     12'd139: toneL = `hc;
                12'd140: toneL = `b;     12'd141: toneL = `hc;
                12'd142: toneL = `b;     12'd143: toneL = `hc;

                12'd144: toneL = `e;     12'd145: toneL = `e;
                12'd146: toneL = `e;     12'd147: toneL = `e;
                12'd148: toneL = `e;     12'd149: toneL = `e;
                12'd150: toneL = `e;     12'd151: toneL = `e;
                12'd152: toneL = `b;     12'd153: toneL = `hc;
                12'd154: toneL = `b;     12'd155: toneL = `hc;
                12'd156: toneL = `b;     12'd157: toneL = `hc;
                12'd158: toneL = `b;     12'd159: toneL = `hc;

                12'd160: toneL = `e;     12'd161: toneL = `e;
                12'd162: toneL = `e;     12'd163: toneL = `e;
                12'd164: toneL = `e;     12'd165: toneL = `e;
                12'd166: toneL = `e;     12'd167: toneL = `e;
                12'd168: toneL = `b;     12'd169: toneL = `hc;
                12'd170: toneL = `b;     12'd171: toneL = `hc;
                12'd172: toneL = `b;     12'd173: toneL = `hc;
                12'd174: toneL = `b;     12'd175: toneL = `hc;

                12'd176: toneL = `e;     12'd177: toneL = `e;
                12'd178: toneL = `e;     12'd179: toneL = `e;
                12'd180: toneL = `e;     12'd181: toneL = `e;
                12'd182: toneL = `e;     12'd183: toneL = `e;
                12'd184: toneL = `b;     12'd185: toneL = `hc;
                12'd186: toneL = `b;     12'd187: toneL = `hc;
                12'd188: toneL = `b;     12'd189: toneL = `hc;
                12'd190: toneL = `b;     12'd191: toneL = `hc;

                                // --- Measure 4 ---
                12'd192: toneL = `f;     12'd193: toneL = `f;
                12'd194: toneL = `f;     12'd195: toneL = `f;
                12'd196: toneL = `f;     12'd197: toneL = `f;
                12'd198: toneL = `f;     12'd199: toneL = `f;
                12'd200: toneL = `a;     12'd201: toneL = `hc;
                12'd202: toneL = `a;     12'd203: toneL = `hc;
                12'd204: toneL = `a;     12'd205: toneL = `hc;
                12'd206: toneL = `a;     12'd207: toneL = `hc;

                12'd208: toneL = `f;     12'd209: toneL = `f;
                12'd210: toneL = `f;     12'd211: toneL = `f;
                12'd212: toneL = `f;     12'd213: toneL = `f;
                12'd214: toneL = `f;     12'd215: toneL = `f;
                12'd216: toneL = `a;     12'd217: toneL = `hc;
                12'd218: toneL = `a;     12'd219: toneL = `hc;
                12'd220: toneL = `a;     12'd221: toneL = `hc;
                12'd222: toneL = `a;     12'd223: toneL = `hc;

                12'd224: toneL = `f;     12'd225: toneL = `f;
                12'd226: toneL = `f;     12'd227: toneL = `f;
                12'd228: toneL = `f;     12'd229: toneL = `f;
                12'd230: toneL = `f;     12'd231: toneL = `f;
                12'd232: toneL = `a;     12'd233: toneL = `hc;
                12'd234: toneL = `a;     12'd235: toneL = `hc;
                12'd236: toneL = `a;     12'd237: toneL = `hc;
                12'd238: toneL = `a;     12'd239: toneL = `hc;

                12'd240: toneL = `f;     12'd241: toneL = `f;
                12'd242: toneL = `f;     12'd243: toneL = `f;
                12'd244: toneL = `f;     12'd245: toneL = `f;
                12'd246: toneL = `f;     12'd247: toneL = `f;
                12'd248: toneL = `a;     12'd249: toneL = `hc;
                12'd250: toneL = `a;     12'd251: toneL = `hc;
                12'd252: toneL = `a;     12'd253: toneL = `hc;
                12'd254: toneL = `a;     12'd255: toneL = `hc;

                                // --- Measure 5 ---
                12'd256: toneL = `f;     12'd257: toneL = `f;
                12'd258: toneL = `f;     12'd259: toneL = `f;
                12'd260: toneL = `f;     12'd261: toneL = `f;
                12'd262: toneL = `f;     12'd263: toneL = `f;
                12'd264: toneL = `b;     12'd265: toneL = `hd;
                12'd266: toneL = `b;     12'd267: toneL = `hd;
                12'd268: toneL = `b;     12'd269: toneL = `hd;
                12'd270: toneL = `b;     12'd271: toneL = `hd;

                12'd272: toneL = `f;     12'd273: toneL = `f;
                12'd274: toneL = `f;     12'd275: toneL = `f;
                12'd276: toneL = `f;     12'd277: toneL = `f;
                12'd278: toneL = `f;     12'd279: toneL = `f;
                12'd280: toneL = `b;     12'd281: toneL = `hd;
                12'd282: toneL = `b;     12'd283: toneL = `hd;
                12'd284: toneL = `b;     12'd285: toneL = `hd;
                12'd286: toneL = `b;     12'd287: toneL = `hd;

                12'd288: toneL = `f;     12'd289: toneL = `f;
                12'd290: toneL = `f;     12'd291: toneL = `f;
                12'd292: toneL = `f;     12'd293: toneL = `f;
                12'd294: toneL = `f;     12'd295: toneL = `f;
                12'd296: toneL = `b;     12'd297: toneL = `hd;
                12'd298: toneL = `b;     12'd299: toneL = `hd;
                12'd300: toneL = `b;     12'd301: toneL = `hd;
                12'd302: toneL = `b;     12'd303: toneL = `hd;

                12'd304: toneL = `f;     12'd305: toneL = `f;
                12'd306: toneL = `f;     12'd307: toneL = `f;
                12'd308: toneL = `f;     12'd309: toneL = `f;
                12'd310: toneL = `f;     12'd311: toneL = `f;
                12'd312: toneL = `b;     12'd313: toneL = `hd;
                12'd314: toneL = `b;     12'd315: toneL = `hd;
                12'd316: toneL = `b;     12'd317: toneL = `hd;
                12'd318: toneL = `b;     12'd319: toneL = `hd;

                                // --- Measure 6 ---
                12'd320: toneL = `f;     12'd321: toneL = `f;
                12'd322: toneL = `f;     12'd323: toneL = `f;
                12'd324: toneL = `f;     12'd325: toneL = `f;
                12'd326: toneL = `f;     12'd327: toneL = `f;
                12'd328: toneL = `a;     12'd329: toneL = `hc;
                12'd330: toneL = `a;     12'd331: toneL = `hc;
                12'd332: toneL = `a;     12'd333: toneL = `hc;
                12'd334: toneL = `a;     12'd335: toneL = `hc;

                12'd336: toneL = `f;     12'd337: toneL = `f;
                12'd338: toneL = `f;     12'd339: toneL = `f;
                12'd340: toneL = `f;     12'd341: toneL = `f;
                12'd342: toneL = `f;     12'd343: toneL = `f;
                12'd344: toneL = `a;     12'd345: toneL = `hc;
                12'd346: toneL = `a;     12'd347: toneL = `hc;
                12'd348: toneL = `a;     12'd349: toneL = `hc;
                12'd350: toneL = `a;     12'd351: toneL = `hc;

                12'd352: toneL = `f;     12'd353: toneL = `f;
                12'd354: toneL = `f;     12'd355: toneL = `f;
                12'd356: toneL = `f;     12'd357: toneL = `f;
                12'd358: toneL = `f;     12'd359: toneL = `f;
                12'd360: toneL = `a;     12'd361: toneL = `hc;
                12'd362: toneL = `a;     12'd363: toneL = `hc;
                12'd364: toneL = `a;     12'd365: toneL = `hc;
                12'd366: toneL = `a;     12'd367: toneL = `hc;

                12'd368: toneL = `f;     12'd369: toneL = `f;
                12'd370: toneL = `f;     12'd371: toneL = `f;
                12'd372: toneL = `f;     12'd373: toneL = `f;
                12'd374: toneL = `f;     12'd375: toneL = `f;
                12'd376: toneL = `a;     12'd377: toneL = `hc;
                12'd378: toneL = `a;     12'd379: toneL = `hc;
                12'd380: toneL = `a;     12'd381: toneL = `hc;
                12'd382: toneL = `a;     12'd383: toneL = `hc;

                                // --- Measure 7 ---
                12'd384: toneL = `eM;     12'd385: toneL = `eM;
                12'd386: toneL = `eM;     12'd387: toneL = `eM;
                12'd388: toneL = `eM;     12'd389: toneL = `eM;
                12'd390: toneL = `eM;     12'd391: toneL = `eM;
                12'd392: toneL = `b;     12'd393: toneL = `hc;
                12'd394: toneL = `b;     12'd395: toneL = `hc;
                12'd396: toneL = `b;     12'd397: toneL = `hc;
                12'd398: toneL = `b;     12'd399: toneL = `hc;

                12'd400: toneL = `e;     12'd401: toneL = `e;
                12'd402: toneL = `e;     12'd403: toneL = `e;
                12'd404: toneL = `e;     12'd405: toneL = `e;
                12'd406: toneL = `e;     12'd407: toneL = `e;
                12'd408: toneL = `b;     12'd409: toneL = `hc;
                12'd410: toneL = `b;     12'd411: toneL = `hc;
                12'd412: toneL = `b;     12'd413: toneL = `hc;
                12'd414: toneL = `b;     12'd415: toneL = `hc;

                12'd416: toneL = `e;     12'd417: toneL = `e;
                12'd418: toneL = `e;     12'd419: toneL = `e;
                12'd420: toneL = `e;     12'd421: toneL = `e;
                12'd422: toneL = `e;     12'd423: toneL = `e;
                12'd424: toneL = `b;     12'd425: toneL = `hc;
                12'd426: toneL = `b;     12'd427: toneL = `hc;
                12'd428: toneL = `b;     12'd429: toneL = `hc;
                12'd430: toneL = `b;     12'd431: toneL = `hc;

                12'd432: toneL = `e;     12'd433: toneL = `e;
                12'd434: toneL = `e;     12'd435: toneL = `e;
                12'd436: toneL = `e;     12'd437: toneL = `e;
                12'd438: toneL = `e;     12'd439: toneL = `e;
                12'd440: toneL = `b;     12'd441: toneL = `hc;
                12'd442: toneL = `b;     12'd443: toneL = `hc;
                12'd444: toneL = `b;     12'd445: toneL = `hc;
                12'd446: toneL = `b;     12'd447: toneL = `hc;

                                // --- Measure 8 ---
                12'd448: toneL = `f;     12'd449: toneL = `f;
                12'd450: toneL = `f;     12'd451: toneL = `f;
                12'd452: toneL = `f;     12'd453: toneL = `f;
                12'd454: toneL = `f;     12'd455: toneL = `f;
                12'd456: toneL = `a;     12'd457: toneL = `hc;
                12'd458: toneL = `a;     12'd459: toneL = `hc;
                12'd460: toneL = `a;     12'd461: toneL = `hc;
                12'd462: toneL = `a;     12'd463: toneL = `hc;

                12'd464: toneL = `f;     12'd465: toneL = `f;
                12'd466: toneL = `f;     12'd467: toneL = `f;
                12'd468: toneL = `f;     12'd469: toneL = `f;
                12'd470: toneL = `f;     12'd471: toneL = `f;
                12'd472: toneL = `a;     12'd473: toneL = `hc;
                12'd474: toneL = `a;     12'd475: toneL = `hc;
                12'd476: toneL = `a;     12'd477: toneL = `hc;
                12'd478: toneL = `a;     12'd479: toneL = `hc;

                12'd480: toneL = `f;     12'd481: toneL = `f;
                12'd482: toneL = `f;     12'd483: toneL = `f;
                12'd484: toneL = `f;     12'd485: toneL = `f;
                12'd486: toneL = `f;     12'd487: toneL = `f;
                12'd488: toneL = `a;     12'd489: toneL = `hc;
                12'd490: toneL = `a;     12'd491: toneL = `hc;
                12'd492: toneL = `a;     12'd493: toneL = `hc;
                12'd494: toneL = `a;     12'd495: toneL = `hc;

                12'd496: toneL = `f;     12'd497: toneL = `f;
                12'd498: toneL = `f;     12'd499: toneL = `f;
                12'd500: toneL = `f;     12'd501: toneL = `f;
                12'd502: toneL = `f;     12'd503: toneL = `f;
                12'd504: toneL = `f;     12'd505: toneL = `f;
                12'd506: toneL = `f;     12'd507: toneL = `f;
                12'd508: toneL = `f;     12'd509: toneL = `f;
                12'd510: toneL = `f;     12'd511: toneL = `f;

                                // --- Measure 9 ---
                12'd512: toneL = `f;     12'd513: toneL = `f;
                12'd514: toneL = `f;     12'd515: toneL = `f;
                12'd516: toneL = `f;     12'd517: toneL = `f;
                12'd518: toneL = `f;     12'd519: toneL = `f;
                12'd520: toneL = `a;     12'd521: toneL = `hc;
                12'd522: toneL = `a;     12'd523: toneL = `hc;
                12'd524: toneL = `a;     12'd525: toneL = `hc;
                12'd526: toneL = `a;     12'd527: toneL = `hc;

                12'd528: toneL = `f;     12'd529: toneL = `f;
                12'd530: toneL = `f;     12'd531: toneL = `f;
                12'd532: toneL = `f;     12'd533: toneL = `f;
                12'd534: toneL = `f;     12'd535: toneL = `f;
                12'd536: toneL = `a;     12'd537: toneL = `hc;
                12'd538: toneL = `a;     12'd539: toneL = `hc;
                12'd540: toneL = `a;     12'd541: toneL = `hc;
                12'd542: toneL = `a;     12'd543: toneL = `hc;

                12'd544: toneL = `f;     12'd545: toneL = `f;
                12'd546: toneL = `f;     12'd547: toneL = `f;
                12'd548: toneL = `f;     12'd549: toneL = `f;
                12'd550: toneL = `f;     12'd551: toneL = `f;
                12'd552: toneL = `a;     12'd553: toneL = `hc;
                12'd554: toneL = `a;     12'd555: toneL = `hc;
                12'd556: toneL = `a;     12'd557: toneL = `hc;
                12'd558: toneL = `a;     12'd559: toneL = `hc;

                12'd560: toneL = `f;     12'd561: toneL = `f;
                12'd562: toneL = `f;     12'd563: toneL = `f;
                12'd564: toneL = `f;     12'd565: toneL = `f;
                12'd566: toneL = `f;     12'd567: toneL = `f;
                12'd568: toneL = `a;     12'd569: toneL = `hc;
                12'd570: toneL = `a;     12'd571: toneL = `hc;
                12'd572: toneL = `a;     12'd573: toneL = `hc;
                12'd574: toneL = `a;     12'd575: toneL = `hc;

                                // --- Measure 10 ---
                12'd576: toneL = `eM;     12'd577: toneL = `eM;
                12'd578: toneL = `eM;     12'd579: toneL = `eM;
                12'd580: toneL = `eM;     12'd581: toneL = `eM;
                12'd582: toneL = `eM;     12'd583: toneL = `eM;
                12'd584: toneL = `b;     12'd585: toneL = `hc;
                12'd586: toneL = `b;     12'd587: toneL = `hc;
                12'd588: toneL = `b;     12'd589: toneL = `hc;
                12'd590: toneL = `b;     12'd591: toneL = `hc;

                12'd592: toneL = `e;     12'd593: toneL = `e;
                12'd594: toneL = `e;     12'd595: toneL = `e;
                12'd596: toneL = `e;     12'd597: toneL = `e;
                12'd598: toneL = `e;     12'd599: toneL = `e;
                12'd600: toneL = `b;     12'd601: toneL = `hc;
                12'd602: toneL = `b;     12'd603: toneL = `hc;
                12'd604: toneL = `b;     12'd605: toneL = `hc;
                12'd606: toneL = `b;     12'd607: toneL = `hc;

                12'd608: toneL = `e;     12'd609: toneL = `e;
                12'd610: toneL = `e;     12'd611: toneL = `e;
                12'd612: toneL = `e;     12'd613: toneL = `e;
                12'd614: toneL = `e;     12'd615: toneL = `e;
                12'd616: toneL = `b;     12'd617: toneL = `hc;
                12'd618: toneL = `b;     12'd619: toneL = `hc;
                12'd620: toneL = `b;     12'd621: toneL = `hc;
                12'd622: toneL = `b;     12'd623: toneL = `hc;

                12'd624: toneL = `e;     12'd625: toneL = `e;
                12'd626: toneL = `e;     12'd627: toneL = `e;
                12'd628: toneL = `e;     12'd629: toneL = `e;
                12'd630: toneL = `e;     12'd631: toneL = `e;
                12'd632: toneL = `b;     12'd633: toneL = `hc;
                12'd634: toneL = `b;     12'd635: toneL = `hc;
                12'd636: toneL = `b;     12'd637: toneL = `hc;
                12'd638: toneL = `b;     12'd639: toneL = `hc;

                                // --- Measure 11 ---
                12'd640: toneL = `f;     12'd641: toneL = `f;
                12'd642: toneL = `f;     12'd643: toneL = `f;
                12'd644: toneL = `f;     12'd645: toneL = `f;
                12'd646: toneL = `f;     12'd647: toneL = `f;
                12'd648: toneL = `a;     12'd649: toneL = `hc;
                12'd650: toneL = `a;     12'd651: toneL = `hc;
                12'd652: toneL = `a;     12'd653: toneL = `hc;
                12'd654: toneL = `a;     12'd655: toneL = `hc;

                12'd656: toneL = `f;     12'd657: toneL = `f;
                12'd658: toneL = `f;     12'd659: toneL = `f;
                12'd660: toneL = `f;     12'd661: toneL = `f;
                12'd662: toneL = `f;     12'd663: toneL = `f;
                12'd664: toneL = `a;     12'd665: toneL = `hc;
                12'd666: toneL = `a;     12'd667: toneL = `hc;
                12'd668: toneL = `a;     12'd669: toneL = `hc;
                12'd670: toneL = `a;     12'd671: toneL = `hc;

                12'd672: toneL = `f;     12'd673: toneL = `f;
                12'd674: toneL = `f;     12'd675: toneL = `f;
                12'd676: toneL = `f;     12'd677: toneL = `f;
                12'd678: toneL = `f;     12'd679: toneL = `f;
                12'd680: toneL = `a;     12'd681: toneL = `hc;
                12'd682: toneL = `a;     12'd683: toneL = `hc;
                12'd684: toneL = `a;     12'd685: toneL = `hc;
                12'd686: toneL = `a;     12'd687: toneL = `hc;

                12'd688: toneL = `f;     12'd689: toneL = `f;
                12'd690: toneL = `f;     12'd691: toneL = `f;
                12'd692: toneL = `f;     12'd693: toneL = `f;
                12'd694: toneL = `f;     12'd695: toneL = `f;
                12'd696: toneL = `a;     12'd697: toneL = `hc;
                12'd698: toneL = `a;     12'd699: toneL = `hc;
                12'd700: toneL = `a;     12'd701: toneL = `hc;
                12'd702: toneL = `a;     12'd703: toneL = `hc;

                                // --- Measure 12 ---
                12'd704: toneL = `eM;     12'd705: toneL = `eM;
                12'd706: toneL = `eM;     12'd707: toneL = `eM;
                12'd708: toneL = `eM;     12'd709: toneL = `eM;
                12'd710: toneL = `eM;     12'd711: toneL = `eM;
                12'd712: toneL = `b;     12'd713: toneL = `hc;
                12'd714: toneL = `b;     12'd715: toneL = `hc;
                12'd716: toneL = `b;     12'd717: toneL = `hc;
                12'd718: toneL = `b;     12'd719: toneL = `hc;

                12'd720: toneL = `e;     12'd721: toneL = `e;
                12'd722: toneL = `e;     12'd723: toneL = `e;
                12'd724: toneL = `e;     12'd725: toneL = `e;
                12'd726: toneL = `e;     12'd727: toneL = `e;
                12'd728: toneL = `b;     12'd729: toneL = `hc;
                12'd730: toneL = `b;     12'd731: toneL = `hc;
                12'd732: toneL = `b;     12'd733: toneL = `hc;
                12'd734: toneL = `b;     12'd735: toneL = `hc;

                12'd736: toneL = `e;     12'd737: toneL = `e;
                12'd738: toneL = `e;     12'd739: toneL = `e;
                12'd740: toneL = `e;     12'd741: toneL = `e;
                12'd742: toneL = `e;     12'd743: toneL = `e;
                12'd744: toneL = `b;     12'd745: toneL = `hc;
                12'd746: toneL = `b;     12'd747: toneL = `hc;
                12'd748: toneL = `b;     12'd749: toneL = `hc;
                12'd750: toneL = `b;     12'd751: toneL = `hc;

                12'd752: toneL = `e;     12'd753: toneL = `e;
                12'd754: toneL = `e;     12'd755: toneL = `e;
                12'd756: toneL = `e;     12'd757: toneL = `e;
                12'd758: toneL = `e;     12'd759: toneL = `e;
                12'd760: toneL = `b;     12'd761: toneL = `hc;
                12'd762: toneL = `b;     12'd763: toneL = `hc;
                12'd764: toneL = `b;     12'd765: toneL = `hc;
                12'd766: toneL = `b;     12'd767: toneL = `hc;

                                // --- Measure 13 ---
                12'd768: toneL = `f;     12'd769: toneL = `f;
                12'd770: toneL = `f;     12'd771: toneL = `f;
                12'd772: toneL = `f;     12'd773: toneL = `f;
                12'd774: toneL = `f;     12'd775: toneL = `f;
                12'd776: toneL = `a;     12'd777: toneL = `hc;
                12'd778: toneL = `a;     12'd779: toneL = `hc;
                12'd780: toneL = `a;     12'd781: toneL = `hc;
                12'd782: toneL = `a;     12'd783: toneL = `hc;

                12'd784: toneL = `f;     12'd785: toneL = `f;
                12'd786: toneL = `f;     12'd787: toneL = `f;
                12'd788: toneL = `f;     12'd789: toneL = `f;
                12'd790: toneL = `f;     12'd791: toneL = `f;
                12'd792: toneL = `a;     12'd793: toneL = `hc;
                12'd794: toneL = `a;     12'd795: toneL = `hc;
                12'd796: toneL = `a;     12'd797: toneL = `hc;
                12'd798: toneL = `a;     12'd799: toneL = `hc;

                12'd800: toneL = `f;     12'd801: toneL = `f;
                12'd802: toneL = `f;     12'd803: toneL = `f;
                12'd804: toneL = `f;     12'd805: toneL = `f;
                12'd806: toneL = `f;     12'd807: toneL = `f;
                12'd808: toneL = `a;     12'd809: toneL = `hc;
                12'd810: toneL = `a;     12'd811: toneL = `hc;
                12'd812: toneL = `a;     12'd813: toneL = `hc;
                12'd814: toneL = `a;     12'd815: toneL = `hc;

                12'd816: toneL = `f;     12'd817: toneL = `f;
                12'd818: toneL = `f;     12'd819: toneL = `f;
                12'd820: toneL = `f;     12'd821: toneL = `f;
                12'd822: toneL = `f;     12'd823: toneL = `f;
                12'd824: toneL = `a;     12'd825: toneL = `hc;
                12'd826: toneL = `a;     12'd827: toneL = `hc;
                12'd828: toneL = `a;     12'd829: toneL = `hc;
                12'd830: toneL = `a;     12'd831: toneL = `hc;

                                // --- Measure 14 ---
                12'd832: toneL = `eM;     12'd833: toneL = `eM;
                12'd834: toneL = `eM;     12'd835: toneL = `eM;
                12'd836: toneL = `eM;     12'd837: toneL = `eM;
                12'd838: toneL = `eM;     12'd839: toneL = `eM;
                12'd840: toneL = `b;     12'd841: toneL = `hc;
                12'd842: toneL = `b;     12'd843: toneL = `hc;
                12'd844: toneL = `b;     12'd845: toneL = `hc;
                12'd846: toneL = `b;     12'd847: toneL = `hc;

                12'd848: toneL = `e;     12'd849: toneL = `e;
                12'd850: toneL = `e;     12'd851: toneL = `e;
                12'd852: toneL = `e;     12'd853: toneL = `e;
                12'd854: toneL = `e;     12'd855: toneL = `e;
                12'd856: toneL = `b;     12'd857: toneL = `hc;
                12'd858: toneL = `b;     12'd859: toneL = `hc;
                12'd860: toneL = `b;     12'd861: toneL = `hc;
                12'd862: toneL = `b;     12'd863: toneL = `hc;

                12'd864: toneL = `e;     12'd865: toneL = `e;
                12'd866: toneL = `e;     12'd867: toneL = `e;
                12'd868: toneL = `e;     12'd869: toneL = `e;
                12'd870: toneL = `e;     12'd871: toneL = `e;
                12'd872: toneL = `b;     12'd873: toneL = `hc;
                12'd874: toneL = `b;     12'd875: toneL = `hc;
                12'd876: toneL = `b;     12'd877: toneL = `hc;
                12'd878: toneL = `b;     12'd879: toneL = `hc;

                12'd880: toneL = `e;     12'd881: toneL = `e;
                12'd882: toneL = `e;     12'd883: toneL = `e;
                12'd884: toneL = `e;     12'd885: toneL = `e;
                12'd886: toneL = `e;     12'd887: toneL = `e;
                12'd888: toneL = `b;     12'd889: toneL = `hc;
                12'd890: toneL = `b;     12'd891: toneL = `hc;
                12'd892: toneL = `b;     12'd893: toneL = `hc;
                12'd894: toneL = `b;     12'd895: toneL = `hc;

                                // --- Measure 15 ---
                12'd896: toneL = `f;     12'd897: toneL = `f;
                12'd898: toneL = `f;     12'd899: toneL = `f;
                12'd900: toneL = `f;     12'd901: toneL = `f;
                12'd902: toneL = `f;     12'd903: toneL = `f;
                12'd904: toneL = `a;     12'd905: toneL = `hc;
                12'd906: toneL = `a;     12'd907: toneL = `hc;
                12'd908: toneL = `a;     12'd909: toneL = `hc;
                12'd910: toneL = `a;     12'd911: toneL = `hc;

                12'd912: toneL = `f;     12'd913: toneL = `f;
                12'd914: toneL = `f;     12'd915: toneL = `f;
                12'd916: toneL = `f;     12'd917: toneL = `f;
                12'd918: toneL = `f;     12'd919: toneL = `f;
                12'd920: toneL = `a;     12'd921: toneL = `hc;
                12'd922: toneL = `a;     12'd923: toneL = `hc;
                12'd924: toneL = `a;     12'd925: toneL = `hc;
                12'd926: toneL = `a;     12'd927: toneL = `hc;

                12'd928: toneL = `f;     12'd929: toneL = `f;
                12'd930: toneL = `f;     12'd931: toneL = `f;
                12'd932: toneL = `f;     12'd933: toneL = `f;
                12'd934: toneL = `f;     12'd935: toneL = `f;
                12'd936: toneL = `a;     12'd937: toneL = `hc;
                12'd938: toneL = `a;     12'd939: toneL = `hc;
                12'd940: toneL = `a;     12'd941: toneL = `hc;
                12'd942: toneL = `a;     12'd943: toneL = `hc;

                12'd944: toneL = `f;     12'd945: toneL = `f;
                12'd946: toneL = `f;     12'd947: toneL = `f;
                12'd948: toneL = `f;     12'd949: toneL = `f;
                12'd950: toneL = `f;     12'd951: toneL = `f;
                12'd952: toneL = `a;     12'd953: toneL = `hc;
                12'd954: toneL = `a;     12'd955: toneL = `hc;
                12'd956: toneL = `a;     12'd957: toneL = `hc;
                12'd958: toneL = `a;     12'd959: toneL = `hc;

                                // --- Measure 16 ---
                12'd960: toneL = `eM;     12'd961: toneL = `eM;
                12'd962: toneL = `eM;     12'd963: toneL = `eM;
                12'd964: toneL = `eM;     12'd965: toneL = `eM;
                12'd966: toneL = `eM;     12'd967: toneL = `eM;
                12'd968: toneL = `b;     12'd969: toneL = `hc;
                12'd970: toneL = `b;     12'd971: toneL = `hc;
                12'd972: toneL = `b;     12'd973: toneL = `hc;
                12'd974: toneL = `b;     12'd975: toneL = `hc;

                12'd976: toneL = `e;     12'd977: toneL = `e;
                12'd978: toneL = `e;     12'd979: toneL = `e;
                12'd980: toneL = `e;     12'd981: toneL = `e;
                12'd982: toneL = `e;     12'd983: toneL = `e;
                12'd984: toneL = `b;     12'd985: toneL = `hc;
                12'd986: toneL = `b;     12'd987: toneL = `hc;
                12'd988: toneL = `b;     12'd989: toneL = `hc;
                12'd990: toneL = `b;     12'd991: toneL = `hc;

                12'd992: toneL = `e;     12'd993: toneL = `e;
                12'd994: toneL = `e;     12'd995: toneL = `e;
                12'd996: toneL = `e;     12'd997: toneL = `e;
                12'd998: toneL = `e;     12'd999: toneL = `e;
                12'd1000: toneL = `b;     12'd1001: toneL = `hc;
                12'd1002: toneL = `b;     12'd1003: toneL = `hc;
                12'd1004: toneL = `b;     12'd1005: toneL = `hc;
                12'd1006: toneL = `b;     12'd1007: toneL = `hc;

                12'd1008: toneL = `e;     12'd1009: toneL = `e;
                12'd1010: toneL = `e;     12'd1011: toneL = `e;
                12'd1012: toneL = `e;     12'd1013: toneL = `e;
                12'd1014: toneL = `e;     12'd1015: toneL = `e;
                12'd1016: toneL = `b;     12'd1017: toneL = `hc;
                12'd1018: toneL = `b;     12'd1019: toneL = `hc;
                12'd1020: toneL = `b;     12'd1021: toneL = `hc;
                12'd1022: toneL = `b;     12'd1023: toneL = `hc;

               default : toneL = `sil;
            endcase
        end
        else begin
            toneL = `sil;
        end
    end
endmodule




module note_gen(
    input clk, // clock from crystal
    input rst, // active high reset
    input [2:0] volume, 
    input [21:0] note_div_left, // div for note generation
    input [21:0] note_div_right,
    output [15:0] audio_left,
    output [15:0] audio_right
    );

    // Declare internal signals
    reg [21:0] clk_cnt_next, clk_cnt;
    reg [21:0] clk_cnt_next_2, clk_cnt_2;
    reg b_clk, b_clk_next;
    reg c_clk, c_clk_next;

    // Note frequency generation
    // clk_cnt, clk_cnt_2, b_clk, c_clk
    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            begin
                clk_cnt <= 22'd0;
                clk_cnt_2 <= 22'd0;
                b_clk <= 1'b0;
                c_clk <= 1'b0;
            end
        else
            begin
                clk_cnt <= clk_cnt_next;
                clk_cnt_2 <= clk_cnt_next_2;
                b_clk <= b_clk_next;
                c_clk <= c_clk_next;
            end
    
    // clk_cnt_next, b_clk_next
    always @*
        if (clk_cnt == note_div_left)
            begin
                clk_cnt_next = 22'd0;
                b_clk_next = ~b_clk;
            end
        else
            begin
                clk_cnt_next = clk_cnt + 1'b1;
                b_clk_next = b_clk;
            end

    // clk_cnt_next_2, c_clk_next
    always @*
        if (clk_cnt_2 == note_div_right)
            begin
                clk_cnt_next_2 = 22'd0;
                c_clk_next = ~c_clk;
            end
        else
            begin
                clk_cnt_next_2 = clk_cnt_2 + 1'b1;
                c_clk_next = c_clk;
            end

    // Assign the amplitude of the note
    // Volume is controlled here
    reg [15:0] neg_volume_value [0:5] = {
        16'h0000,
        16'hFE00, // -2^9
        16'hFC00, // -2^10
        16'hF800, // -2^11
        16'hF000, // -2^12
        16'hE000  // -2^13
    };
    
    reg [15:0] pos_volume_value [0:5] = {
        16'h0000,
        16'h0200, //  2^9
        16'h0400, //  2^10
        16'h0800, //  2^11
        16'h1000, //  2^12
        16'h2000  //  2^13
    };
    // Assign the amplitude of the note
    // Volume is controlled here 1~5
    assign audio_left = (note_div_left == 22'd1) ? 16'h0000 : 
                                (b_clk == 1'b0) ? neg_volume_value[volume] : pos_volume_value[volume];
    assign audio_right = (note_div_right == 22'd1) ? 16'h0000 : 
                                (c_clk == 1'b0) ? neg_volume_value[volume] : pos_volume_value[volume];
endmodule

/////////////////////////////////////////////////////



module player_control (
	input clk, 
	input reset, 
	input _play, 
	input wire [2:0] _mode, 
    input _start,
	output reg [11:0] ibeat
);
	parameter LEN = 4095;
    reg [11:0] next_ibeat;

	always @(posedge clk, posedge reset) begin
		if (reset) begin
			ibeat <= 0;
		end 
        else begin
            ibeat <= next_ibeat;
		end
	end

    always @* begin
        next_ibeat = (ibeat + 1 < LEN) ? (ibeat + 1) : 0;
        if(_mode==2) begin
            next_ibeat = ibeat;
            
        end
        if(_mode!=2 && _mode!=0) begin
            next_ibeat = 0;
        end
    end

endmodule


module speaker_control(
    input clk,  // clock from the crystal
    input rst,  // active high reset
    input [15:0] audio_in_left, // left channel audio data input
    input [15:0] audio_in_right, // right channel audio data input
    output audio_mclk, // master clock
    output audio_lrck, // left-right clock, Word Select clock, or sample rate clock
    output audio_sck, // serial clock
    output reg audio_sdin // serial audio data input
    ); 

    // Declare internal signal nodes 
    wire [8:0] clk_cnt_next;
    reg [8:0] clk_cnt;
    reg [15:0] audio_left, audio_right;

    // Counter for the clock divider
    assign clk_cnt_next = clk_cnt + 1'b1;

    always @(posedge clk or posedge rst)
        if (rst == 1'b1)
            clk_cnt <= 9'd0;
        else
            clk_cnt <= clk_cnt_next;

    // Assign divided clock output
    assign audio_mclk = clk_cnt[1];
    assign audio_lrck = clk_cnt[8];
    assign audio_sck = 1'b1; // use internal serial clock mode

    // audio input data buffer
    always @(posedge clk_cnt[8] or posedge rst)
        if (rst == 1'b1)
            begin
                audio_left <= 16'd0;
                audio_right <= 16'd0;
            end
        else
            begin
                audio_left <= audio_in_left;
                audio_right <= audio_in_right;
            end

    always @*
        case (clk_cnt[8:4])
            5'b00000: audio_sdin = audio_right[0];
            5'b00001: audio_sdin = audio_left[15];
            5'b00010: audio_sdin = audio_left[14];
            5'b00011: audio_sdin = audio_left[13];
            5'b00100: audio_sdin = audio_left[12];
            5'b00101: audio_sdin = audio_left[11];
            5'b00110: audio_sdin = audio_left[10];
            5'b00111: audio_sdin = audio_left[9];
            5'b01000: audio_sdin = audio_left[8];
            5'b01001: audio_sdin = audio_left[7];
            5'b01010: audio_sdin = audio_left[6];
            5'b01011: audio_sdin = audio_left[5];
            5'b01100: audio_sdin = audio_left[4];
            5'b01101: audio_sdin = audio_left[3];
            5'b01110: audio_sdin = audio_left[2];
            5'b01111: audio_sdin = audio_left[1];
            5'b10000: audio_sdin = audio_left[0];
            5'b10001: audio_sdin = audio_right[15];
            5'b10010: audio_sdin = audio_right[14];
            5'b10011: audio_sdin = audio_right[13];
            5'b10100: audio_sdin = audio_right[12];
            5'b10101: audio_sdin = audio_right[11];
            5'b10110: audio_sdin = audio_right[10];
            5'b10111: audio_sdin = audio_right[9];
            5'b11000: audio_sdin = audio_right[8];
            5'b11001: audio_sdin = audio_right[7];
            5'b11010: audio_sdin = audio_right[6];
            5'b11011: audio_sdin = audio_right[5];
            5'b11100: audio_sdin = audio_right[4];
            5'b11101: audio_sdin = audio_right[3];
            5'b11110: audio_sdin = audio_right[2];
            5'b11111: audio_sdin = audio_right[1];
            default: audio_sdin = 1'b0;
        endcase

endmodule