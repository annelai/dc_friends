module COLOR_TRANSFORM (
	// input port	////
	clk_25,
	reset,
	valid,
	//// input-data ////
	x_i,
	y_i,
	red_i,
	green_i,
	blue_i,

	// output port	////
	wrreq,
	wrclk_25,
	//// output-data ////
	x_o,
	y_o,
	red_o,
	green_o,
	blue_o
);

//==== parameter definition =================================
	
	parameter S_WAIT 	= 2'd0;
	parameter S_COMPUTE	= 2'd1;
//	parameter S_MAT		= 2'd2;
	parameter S_SEND	= 2'd3;

	parameter AMB_SHIFT = 8'd3;

	parameter DVI_CONST = 32'd1;//2^16 = 65536

	parameter VM_1_1	= 32'd0;
	parameter VM_1_2	= 32'd0;
	parameter VM_1_3	= 32'd0;
	parameter VM_1_4	= 32'd0;
	parameter VM_1_5	= 32'd0;
	parameter VM_1_6	= 32'd0;
	parameter VM_1_7	= 32'd0; 
	parameter VM_1_8	= 32'd0;
	parameter VM_1_9	= 32'd0;
	parameter VM_1_10	= 32'd0;
	parameter VM_1_11	= 32'd0;
	parameter VM_1_12	= 32'd0;
	parameter VM_1_13	= 32'd0;
	parameter VM_1_14	= 32'd0;
	parameter VM_1_15	= 32'd0;
	parameter VM_1_16	= 32'd1;
	parameter VM_1_17	= 32'd0;
	parameter VM_1_18	= 32'd0;

	parameter VM_2_1	= 32'd0;
	parameter VM_2_2	= 32'd0;
	parameter VM_2_3	= 32'd0;
	parameter VM_2_4	= 32'd0;
	parameter VM_2_5	= 32'd0;
	parameter VM_2_6	= 32'd0;
	parameter VM_2_7	= 32'd0; 
	parameter VM_2_8	= 32'd0;
	parameter VM_2_9	= 32'd0;
	parameter VM_2_10	= 32'd0;
	parameter VM_2_11	= 32'd0;
	parameter VM_2_12	= 32'd0;
	parameter VM_2_13	= 32'd0;
	parameter VM_2_14	= 32'd0;
	parameter VM_2_15	= 32'd0;
	parameter VM_2_16	= 32'd0;
	parameter VM_2_17	= 32'd1;
	parameter VM_2_18	= 32'd0;

	parameter VM_3_1	= 32'd0;
	parameter VM_3_2	= 32'd0;
	parameter VM_3_3	= 32'd0;
	parameter VM_3_4	= 32'd0;
	parameter VM_3_5	= 32'd0;
	parameter VM_3_6	= 32'd0;
	parameter VM_3_7	= 32'd0; 
	parameter VM_3_8	= 32'd0;
	parameter VM_3_9	= 32'd0;
	parameter VM_3_10	= 32'd0;
	parameter VM_3_11 	= 32'd0;
	parameter VM_3_12	= 32'd0;
	parameter VM_3_13	= 32'd0;
	parameter VM_3_14	= 32'd0;
	parameter VM_3_15	= 32'd0;
	parameter VM_3_16	= 32'd0;
	parameter VM_3_17	= 32'd0;
	parameter VM_3_18	= 32'd1;

//==== in/out declaration ===================================
	//---- input ----//
	input clk_25;
	input reset;
	input valid;

	input [9:0] x_i;
	input [9:0] y_i;
	input [7:0] red_i;
	input [7:0] green_i;
	input [7:0] blue_i;

	//---- output ----//
	output wrreq;
	output wrclk_25;
	
	output [9:0] x_o;
	output [9:0] y_o;
	output [7:0] red_o;
	output [7:0] green_o;
	output [7:0] blue_o;

//==== reg/wire declaration =================================
	//---- output ----//
	reg [9:0] x_o;
	reg [9:0] y_o;
	reg [7:0] red_o;
	reg [7:0] green_o;
	reg [7:0] blue_o;
	reg wrreq;
	reg next_wrreq;
	wire wrclk_25;

	//---- flip-flops ----//
	reg [1:0] state;
	reg [1:0] next_state;
	//reg [9:0] x;
	//reg [9:0] y;
	//reg [7:0] red;
	//reg [7:0] green;
	//reg [7:0] blue;
    reg [9:0] next_x_o;
	reg [9:0] next_y_o;
	reg [7:0] next_red_o;
 	reg [7:0] next_green_o;
	reg [7:0] next_blue_o;

	reg	[31:0] p18; // R3
	reg [31:0] p17;	// G3
	reg	[31:0] p16; // B3
	reg	[31:0] p15; // R2G
	reg	[31:0] p14; // RG2
	reg	[31:0] p13; // G2B
	reg	[31:0] p12; // GB2
	reg	[31:0] p11; // B2R
	reg	[31:0] p10; // BR2
	reg	[31:0] p9; // R2
	reg	[31:0] p8; // G2
	reg	[31:0] p7; // B2
	reg	[31:0] p6; // RG
	reg	[31:0] p5; // GB
	reg	[31:0] p4; // BR
	reg	[31:0] p3; // R
	reg	[31:0] p2; // G
	reg	[31:0] p1; // B

	reg	[31:0] next_p18; // R3
	reg [31:0] next_p17; // G3
	reg	[31:0] next_p16; // B3
	reg	[31:0] next_p15; // R2G
	reg	[31:0] next_p14; // RG2
	reg	[31:0] next_p13; // G2B
	reg	[31:0] next_p12; // GB2
	reg	[31:0] next_p11; // B2R
	reg	[31:0] next_p10; // BR2
	reg	[31:0] next_p9; // R2
	reg	[31:0] next_p8; // G2
	reg	[31:0] next_p7; // B2
	reg	[31:0] next_p6; // RG
	reg	[31:0] next_p5; // GB
	reg	[31:0] next_p4; // 32
	reg	[31:0] next_p3; // R
	reg	[31:0] next_p2; // G
	reg	[31:0] next_p1; // B
//==== combinational part ===================================
	// clock signal
	assign wrclk_25 = clk_25;

	always@(*) begin
		case(state)
			S_WAIT: begin
				next_state = state;
				next_x_o = x_o;
				next_y_o = y_o;
				next_red_o = red_o;
				next_green_o = green_o;
				next_blue_o = blue_o;
				next_wrreq = wrreq;

				next_p18 = p18;			
				next_p17 = p17;
				next_p16 = p16;
				next_p15 = p15;
				next_p14 = p14;
				next_p13 = p13;
				next_p12 = p12;
				next_p11 = p11;
				next_p10 = p10;
				next_p9 = p9;
				next_p8 = p8;
				next_p7 = p7;
				next_p6 = p6;
				next_p5 = p5;
				next_p4 = p4;
				next_p3 = p3;
				next_p2 = p2;
				next_p1 = p1;

				if(valid) begin
					next_state = S_COMPUTE;
					next_x_o = x_i;
					next_y_o = y_i;
					next_red_o = red_i;
					next_green_o = green_i;
					next_blue_o = blue_i;
					next_wrreq = 0;

					next_p18 = red_i*red_i*red_i;
					next_p17 = green_i*green_i*green_i;
					next_p16 = blue_i*blue_i*blue_i;
					next_p15 = red_i*red_i*green_i;
					next_p14 = red_i*green_i*green_i;
					next_p13 = green_i*green_i*blue_i;
					next_p12 = green_i*blue_i*blue_i;
					next_p11 = blue_i*blue_i*red_i;
					next_p10 = blue_i*red_i*red_i;
					next_p9 = red_i*red_i;
					next_p8 = green_i*green_i;
					next_p7 = blue_i*blue_i;
					next_p6 = red_i*green_i;
					next_p5 = green_i*blue_i;
					next_p4 = blue_i*red_i;
					next_p3 = red_i;
					next_p2 = green_i;
					next_p1 = blue_i;

				end
				else begin

				end
			end

			S_COMPUTE: begin
				next_state = S_SEND;
				next_x_o = x_o;
				next_y_o = y_o;
				next_wrreq = wrreq;

				next_p18 = p18;			
				next_p17 = p17;
				next_p16 = p16;
				next_p15 = p15;
				next_p14 = p14;
				next_p13 = p13;
				next_p12 = p12;
				next_p11 = p11;
				next_p10 = p10;
				next_p9 = p9;
				next_p8 = p8;
				next_p7 = p7;
				next_p6 = p6;
				next_p5 = p5;
				next_p4 = p4;
				next_p3 = p3;
				next_p2 = p2;
				next_p1 = p1;

				next_red_o = (VM_1_1*p18 + VM_1_2*p17 + VM_1_3*p16 + VM_1_4*p15 + VM_1_5*p14 + VM_1_6*p13 + VM_1_7*p12 + VM_1_8*p11 + VM_1_9*p10 + VM_1_10*p9 + VM_1_11*p8 + VM_1_12*p7 + VM_1_13*p6 + VM_1_14*p5 + VM_1_15*p4 + VM_1_16*p3 + VM_1_17*p2 + VM_1_18*p1) / DVI_CONST;
				next_green_o = (VM_2_1*p18 + VM_1_2*p17 + VM_2_3*p16 + VM_2_4*p15 + VM_2_5*p14 + VM_2_6*p13 + VM_2_7*p12 + VM_2_8*p11 + VM_2_9*p10 + VM_2_10*p9 + VM_2_11*p8 + VM_2_12*p7 + VM_2_13*p6 + VM_2_14*p5 + VM_2_15*p4 + VM_2_16*p3 + VM_2_17*p2 + VM_2_18*p1) / DVI_CONST;
				next_blue_o = (VM_3_1*p18 + VM_1_2*p17 + VM_3_3*p16 + VM_3_4*p15 + VM_3_5*p14 + VM_3_6*p13 + VM_3_7*p12 + VM_3_8*p11 + VM_3_9*p10 + VM_3_10*p9 + VM_3_11*p8 + VM_3_12*p7 + VM_3_13*p6 + VM_3_14*p5 + VM_3_15*p4 + VM_3_16*p3 + VM_3_17*p2 + VM_3_18*p1) / DVI_CONST;

			end

			S_SEND: begin
				next_state = S_WAIT;
				next_wrreq = 1;
				next_x_o = x_o;
				next_y_o = y_o;
				next_red_o = red_o;
				next_green_o = green_o;
				next_blue_o = blue_o;

				next_p18 = p18;			
				next_p17 = p17;
				next_p16 = p16;
				next_p15 = p15;
				next_p14 = p14;
				next_p13 = p13;
				next_p12 = p12;
				next_p11 = p11;
				next_p10 = p10;
				next_p9 = p9;
				next_p8 = p8;
				next_p7 = p7;
				next_p6 = p6;
				next_p5 = p5;
				next_p4 = p4;
				next_p3 = p3;
				next_p2 = p2;
				next_p1 = p1;

			end

			default: begin
				next_state = state;
				next_x_o = x_o;
				next_y_o = y_o;
				next_red_o = red_o;
				next_green_o = green_o;
				next_blue_o = blue_o;
				next_wrreq = wrreq;

				next_p18 = p18;			
				next_p17 = p17;
				next_p16 = p16;
				next_p15 = p15;
				next_p14 = p14;
				next_p13 = p13;
				next_p12 = p12;
				next_p11 = p11;
				next_p10 = p10;
				next_p9 = p9;
				next_p8 = p8;
				next_p7 = p7;
				next_p6 = p6;
				next_p5 = p5;
				next_p4 = p4;
				next_p3 = p3;
				next_p2 = p2;
				next_p1 = p1;
			end
		endcase
	end

//==== sequential part ======================================
	always@( posedge clk_25 or negedge reset ) begin
		if( reset == 0 ) begin
			state 		<= 2'd0;
			wrreq 		<= 0;
			x_o			<= 10'd0;
			y_o			<= 10'd0;
			red_o		<= 8'd0;
			green_o		<= 8'd0;
			blue_o		<= 8'd0;

			p18 		<= 32'd0;			
			p17 		<= 32'd0;
			p16 		<= 32'd0;
			p15 		<= 32'd0;
			p14 		<= 32'd0;
			p13 		<= 32'd0;
			p12 		<= 32'd0;
			p11 		<= 32'd0;
			p10 		<= 32'd0;			
			p9 			<= 32'd0;
			p8 			<= 32'd0;
			p7 			<= 32'd0;
			p6 			<= 32'd0;
			p5 			<= 32'd0;
			p4 			<= 32'd0;
			p3 			<= 32'd0;
			p2 			<= 32'd0;
			p1 			<= 32'd0;


		end
		else begin
			state 		<= next_state;
			wrreq 		<= next_wrreq;
			x_o			<= next_x_o;
			y_o			<= next_y_o;
			red_o		<= next_red_o;
			green_o		<= next_green_o;
			blue_o		<= next_blue_o;	

			p18 		<= next_p18;
			p17 		<= next_p17;
			p16 		<= next_p16;
			p15 		<= next_p15;
			p14 		<= next_p14;
			p13 		<= next_p13;
			p12 		<= next_p12;
			p11 		<= next_p11;
			p10 		<= next_p10;			
			p9 			<= next_p9;
			p8 			<= next_p8;
			p7 			<= next_p7;
			p6 			<= next_p6;
			p5 			<= next_p5;
			p4 			<= next_p4;
			p3 			<= next_p3;
			p2 			<= next_p2;
			p1 			<= next_p1;
		end
	end

endmodule