module Lab8(
    input clk,
    input rst,
    input echo,
    input left_track,
    input right_track,
    input mid_track,
    output trig,
    output IN1,
    output IN2,
    output IN3, 
    output IN4,
    output left_pwm,
    output right_pwm,
    output reg [15:0] LED,
    output reg [6:0] display,
	output reg [3:0] digit
);
    // We have connected the motor and sonic_top modules in the template file for you.
    // TODO: control the motors with the information you get from ultrasonic sensor and 3-way track sensor.
    wire [1:0] mode;
    wire [19:0] distance;

    motor A(
        .clk(clk),
        .rst(rst),
        .mode(mode), //distance <= 30? 2'b00 : 
        .pwm({left_pwm, right_pwm}),
        .l_IN({IN1, IN2}),
        .r_IN({IN3, IN4})
    );


    sonic_top B(
        .clk(clk), 
        .rst(rst), 
        .Echo(echo), 
        .Trig(trig),
        .distance(distance)
    );


    tracker_sensor C(
        .clk(clk),
        .reset(rst), 
        .left_track(left_track), 
        .right_track(right_track), 
        .mid_track(mid_track), 
        .state(mode)
    );



    always @(*) begin
        if((mid_track==0 && right_track==0 && left_track==0) || (mid_track==0 && right_track==1 && left_track==1) || (mid_track==1 && right_track==0 && left_track==0) || (mid_track==0 && right_track==0 && left_track==1) || (mid_track==0 && right_track==1 && left_track==0)) begin
            LED = 16'b0000001111100000;
        end
        else if((mid_track==1 && right_track==0 && left_track==1)) begin
            LED = 16'b0000000000011111;
        end
        else if((mid_track==1 && right_track==1 && left_track==0)) begin
            LED = 16'b0111110000000000;
        end
        else begin
            LED = 16'b1000000000000000;
        end
    end

    wire clk_div16;
    clock_divider #(.n(16)) clock_div15(.clk(clk), .clk_div(clk_div16));

    reg [3:0] bcd_0;
    reg [3:0] bcd_1;
    reg [3:0] bcd_2;
    reg [3:0] bcd_3;
    
    always @(distance) begin
        if (distance > 20'd9999) begin
            bcd_0 = 4'd9;
            bcd_1 = 4'd9;
            bcd_2 = 4'd9;
            bcd_3 = 4'd9;
        end else begin
            bcd_0 = distance % 10;
            bcd_1 = distance / 10 % 10;    
            bcd_2 = distance / 100 % 10;
            bcd_3 = distance / 1000;
        end
    end

    reg [3:0] value;
    always @(posedge clk_div16) begin
        case(digit)
        4'b1110: begin
            digit <= 4'b1101;
            value <= bcd_1;
        end
        4'b1101: begin
            digit <= 4'b1011;
            value <= bcd_2;
        end
        4'b1011: begin
            digit <= 4'b0111;
            value <= bcd_3;
        end
        4'b0111: begin
            digit <= 4'b1110;
            value <= bcd_0;
        end
        default: begin
            digit <= 4'b1110;
            value <= bcd_0;
        end
        endcase
    end

    always @ (*) begin
    	case (value)
    		0 : display = 7'b1000000;	//0000
			1 : display = 7'b1111001;   //0001                                                
			2 : display = 7'b0100100;   //0010                                                
			3 : display = 7'b0110000;   //0011                                             
			4 : display = 7'b0011001;   //0100                                               
			5 : display = 7'b0010010;   //0101                                               
			6 : display = 7'b0000010;   //0110
			7 : display = 7'b1111000;   //0111
			8 : display = 7'b0000000;   //1000
			9 : display = 7'b0010000;	//1001
			default : display = 7'b1111111;
    	endcase
    end


endmodule


module tracker_sensor(clk, reset, left_track, right_track, mid_track, state);
    input clk;
    input reset;
    input left_track, right_track, mid_track;
    output reg [1:0] state;

    // TODO: Receive three tracks and make your own policy.
    // Hint: You can use output state to change your action.

    parameter STOP = 2'b00;
    parameter FORWORD = 2'b01;
    parameter RIGHT = 2'b10;
    parameter LEFT = 2'b11;
    reg [1:0] next_state;

    always @(posedge clk or posedge reset) begin
        if(reset) begin
            state <= STOP;
        end
        else begin
            state <= next_state;
        end
    end

    always @(*) begin
        if((mid_track==0 && right_track==0 && left_track==0) || (mid_track==0 && right_track==1 && left_track==1) || (mid_track==1 && right_track==0 && left_track==0) || (mid_track==0 && right_track==0 && left_track==1) || (mid_track==0 && right_track==1 && left_track==0)) begin
            next_state = FORWORD;
        end
        else if((mid_track==1 && right_track==0 && left_track==1)) begin
            next_state = RIGHT;
        end
        else if((mid_track==1 && right_track==1 && left_track==0)) begin
            next_state = LEFT;
        end
        else begin
            next_state = STOP;
        end
    end

endmodule


module motor(
    input clk,
    input rst,
    input [1:0]mode,
    output [1:0]pwm,
    output [1:0]r_IN,
    output [1:0]l_IN
);

    reg [9:0]left_motor, right_motor;
    wire left_pwm, right_pwm;

    motor_pwm m0(clk, rst, left_motor, left_pwm);
    motor_pwm m1(clk, rst, right_motor, right_pwm);

    assign pwm = {left_pwm,right_pwm};

    // TODO: trace the rest of motor.v and control the speed and direction of the two motors
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            left_motor <= 10'd0;
            right_motor <= 10'd0;
        end else begin
            case (mode)
                2'b00: begin
                    left_motor <= 10'd0; 
                    right_motor <= 10'd0;
                end
                2'b01: begin 
                    left_motor <= 10'd800;
                    right_motor <= 10'd800;
                end
                2'b10: begin 
                    left_motor <= 10'd800;
                    right_motor <= 10'd0;
                end
                2'b11: begin 
                    left_motor <= 10'd0;
                    right_motor <= 10'd800;
                end
                default: begin
                    left_motor <= 10'd0;
                    right_motor <= 10'd0;
                end
            endcase
        end
    end

    assign l_IN = (mode==2'b00)? 2'b00: //不動
                  (mode==2'b01)? 2'b10: //向前
                  (mode==2'b10)? 2'b10: //向右
                  (mode==2'b11)? 2'b00: //向左
                  2'b00;

    assign r_IN = (mode==2'b00)? 2'b00: //不動
                  (mode==2'b01)? 2'b01: //向前
                  (mode==2'b10)? 2'b00: //向右
                  (mode==2'b11)? 2'b01: //向左
                  2'b00;

    
endmodule

module motor_pwm (
    input clk,
    input reset,
    input [9:0]duty,
	output pmod_1 //PWM
);
        
    PWM_gen pwm_0 ( 
        .clk(clk), 
        .reset(reset), 
        .freq(32'd25000),
        .duty(duty), 
        .PWM(pmod_1)
    );

endmodule

//generte PWM by input frequency & duty cycle
module PWM_gen (
    input wire clk,
    input wire reset,
	input [31:0] freq,
    input [9:0] duty,
    output reg PWM
);
    wire [31:0] count_max = 100_000_000 / freq; //4000
    wire [31:0] count_duty = count_max * duty / 1024;
    reg [31:0] count;
        
    always @(posedge clk, posedge reset) begin
        if (reset) begin
            count <= 0;
            PWM <= 0;
        end else if (count < count_max) begin
            count <= count + 1;
            // TODO: set <PWM> accordingly
            PWM <= (count < count_duty) ? 1:0;

        end else begin
            count <= 0;
            PWM <= 0;
        end
    end
endmodule


module sonic_top(clk, rst, Echo, Trig, distance);
	input clk, rst, Echo;
	output Trig;
    output [19:0] distance;

	wire[19:0] dis;
    wire clk1M;
	wire clk_2_17;

    assign distance = dis;

    div clk1(clk ,clk1M);
	TrigSignal u1(.clk(clk), .rst(rst), .trig(Trig));
	PosCounter u2(.clk(clk1M), .rst(rst), .echo(Echo), .distance_count(dis));
 
endmodule

module PosCounter(clk, rst, echo, distance_count); 
    input clk, rst, echo;
    output[19:0] distance_count;

    parameter S0 = 2'b00;
    parameter S1 = 2'b01; 
    parameter S2 = 2'b10;
    
    wire start, finish;
    reg[1:0] curr_state, next_state;
    reg echo_reg1, echo_reg2;
    reg[19:0] count, distance_register;
    wire[19:0] distance_count; 

    always@(posedge clk) begin
        if(rst) begin
            echo_reg1 <= 0;
            echo_reg2 <= 0;
            count <= 0;
            distance_register  <= 0;
            curr_state <= S0;
        end
        else begin
            echo_reg1 <= echo;   
            echo_reg2 <= echo_reg1; 
            case(curr_state)
                S0:begin
                    if (start) curr_state <= next_state; //S1
                    else count <= 0;
                end
                S1:begin
                    if (finish) curr_state <= next_state; //S2
                    else count <= count + 1;
                end
                S2:begin
                    distance_register <= count;
                    count <= 0;
                    curr_state <= next_state; //S0
                end
            endcase
        end
    end

    always @(*) begin
        case(curr_state)
            S0:next_state = S1;
            S1:next_state = S2;
            S2:next_state = S0;
            default:next_state = S0;
        endcase
    end

    assign start = echo_reg1 & ~echo_reg2;  
    assign finish = ~echo_reg1 & echo_reg2;

    // TODO: trace the code and calculate the distance, output it to <distance_count>
    assign distance_count = distance_register * 17/1000;
endmodule

// send trigger signal to sensor
module TrigSignal(clk, rst, trig);
    input clk, rst;
    output trig;

    reg trig, next_trig;
    reg[23:0] count, next_count;

    always @(posedge clk, posedge rst) begin
        if (rst) begin
            count = 0;
            trig = 0;
        end
        else begin
            count = (count >= 10001001)? 0 : count + 1;
            trig = next_trig;
        end
    end

    // count 10us to set <trig> high and wait for 100ms, then set <trig> back to low  10^-5    10^-1
    always @(*) begin
        next_trig = trig;
        // next_count = count + 1;
        // TODO: set <next_trig> and <next_count> to let the sensor work properly
        if(count >= 1000) begin
            next_trig = 1;
        end
        else if(count >= 10001000) begin
            next_trig = 0;
            // count = 0;
        end
    end

endmodule

// clock divider for T = 1us clock
module div(clk ,out_clk);
    input clk;
    output out_clk;
    reg out_clk;
    reg [6:0]cnt;
    
    always @(posedge clk) begin   
        if(cnt < 7'd50) begin
            cnt <= cnt + 1'b1;
            out_clk <= 1'b1;
        end 
        else if(cnt < 7'd100) begin
	        cnt <= cnt + 1'b1;
	        out_clk <= 1'b0;
        end
        else if(cnt == 7'd100) begin
            cnt <= 0;
            out_clk <= 1'b1;
        end
    end
endmodule