module color_transform (
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
	
	parameter AMB_SHIFT = 8'd30;
	parameter S_WAIT 	= 2'd0;
	parameter S_SEND	= 2'd1;

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
    reg [9:0] next_x;
	reg [9:0] next_y;
	reg [7:0] next_red;
 	reg [7:0] next_green;
	reg [7:0] next_blue;

//==== combinational part ===================================
	// clock signal
	assign wrclk_25 = clk_25;

	always@(*) begin
		case(state)
			S_WAIT: begin
				if(valid) begin
					next_state = S_SEND;
					next_x = x_i;
					next_y = y_i;
					next_red = red_i + AMB_SHIFT;
					next_green = green_i + AMB_SHIFT;
					next_blue = blue_i + AMB_SHIFT;
					next_wrreq = 1;
				end
				else begin
					next_state = state;
					next_x = x_o;
					next_y = y_o;
					next_red = red_o;
					next_green = green_o;
					next_blue = blue_o;
					next_wrreq = wrreq;
				end
			end
			S_SEND: begin
				next_state = S_WAIT;
				next_x = x_o;
				next_y = y_o;
				next_red = red_o;
				next_green = green_o;
				next_blue = blue_o;
				next_wrreq = 0;
			end
			default: begin
				next_state = state;
				next_x = x_o;
				next_y = y_o;
				next_red = red_o;
				next_green = green_o;
				next_blue = blue_o;
				next_wrreq = wrreq;
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

		end
		else begin
			state 		<= next_state;
			wrreq 		<= next_wrreq;
			x_o			<= next_x;
			y_o			<= next_y;
			red_o		<= next_red;
			green_o		<= next_green;
			blue_o		<= next_blue;	

		end
	end

endmodule