module ALT (
	// input port //
	clk_25,
	reset,
	//// input data ////
	syncX_i,
	syncY_i,
	DVI_R_i,	// 5 bit
	DVI_G_i,	// 6 bit
	DVI_B_i,	// 5 bit
	CCD_R_i,	// 5 bit 
	CCD_G_i, 	// 6 bit
	CCD_B_i, 	// 5 bit
	// output port //
	//// output-data ////
	AMB_SHIFT_R_o,
	AMB_SHIFT_G_o,
	AMB_SHIFT_B_o,
	thershold_o
);

//==== parameter definition =================================
	parameter FRAME_PIX	= 32'd307200; // = 640*480  

//==== in/out declaration ===================================
	//---- input ----//
	input clk_25;
	input reset;

	input [9:0] syncX_i, syncY_i;
	input [4:0] DVI_R_i, DVI_B_i;
	input [5:0] DVI_G_i;
	input [4:0] CCD_R_i, CCD_B_i;
	input [5:0] CCD_G_i;
	//---- output ----//
	output [7:0] AMB_SHIFT_R_o, AMB_SHIFT_G_o, AMB_SHIFT_B_o;
	output [31:0] thershold_o;

//==== reg/wire declaration =================================
	//---- output ----//
	reg [7:0] AMB_SHIFT_R_o, AMB_SHIFT_G_o, AMB_SHIFT_B_o;
	reg [7:0] next_AMB_SHIFT_R_o, next_AMB_SHIFT_G_o, next_AMB_SHIFT_B_o;
	reg [31:0] thershold_o;
	reg [31:0] next_thershold_o;

	//---- wire ----//
	wire [5:0] delR, delG, delB;
	wire [31:0] FDs2;
	//---- flip-flops ----//
	reg [31:0] tAMB_R, tAMB_G, tAMB_B;
	reg [31:0] next_tAMB_R, next_tAMB_G, next_tAMB_B; 
	reg [31:0] tFDs2, next_tFDs2;
	reg [31:0] mFDs2, next_mFDs2;
	reg [63:0] tDev, next_tDev;
	reg [63:0] Devs2, next_Devs2;

//==== combinational part ===================================
	// absolute difference
	assign delR = (DVI_R_i > CCD_R_i) ? {(DVI_R_i - CCD_R_i), 1'b0} : {(CCD_R_i - DVI_R_i), 1'b0};
	assign delG = (DVI_G_i > CCD_G_i) ? (DVI_G_i - CCD_G_i) : (CCD_G_i - DVI_G_i);
	assign delB = (DVI_B_i > CCD_B_i) ? {(DVI_B_i - CCD_B_i), 1'b0} : {(CCD_B_i - DVI_B_i), 1'b0};	
	// FD^2 = (dR^2 + dG^2 + dB^2)
	assign FDs2 = delR*delR + delG*delG + delB*delB;

	// frame done 640*480 output
	always@(*) begin 			// Ambient Light Shift (mean)	
		next_AMB_SHIFT_R_o = AMB_SHIFT_R_o;
		next_AMB_SHIFT_G_o = AMB_SHIFT_G_o;
		next_AMB_SHIFT_B_o = AMB_SHIFT_B_o;

		next_tAMB_R = tAMB_R;
		next_tAMB_G = tAMB_G;
		next_tAMB_B = tAMB_B;

		if((syncX_i != 10'd639)&&(syncY_i != 10'd479)) begin
			// 	add AMB
			next_tAMB_R = tAMB_R + delR; // 6 bit
			next_tAMB_G = tAMB_G + delG; // 6 bit						
			next_tAMB_B = tAMB_B + delB; // 6 bit 
		end
		else begin 	
			// averge AMB
			next_AMB_SHIFT_R_o = {(tAMB_R + delR), 2'b0} / FRAME_PIX; // 6 -> 8 bit
			next_AMB_SHIFT_G_o = {(tAMB_G + delG), 2'b0} / FRAME_PIX; // 6 -> 8 bit						// -> 8 bit
			next_AMB_SHIFT_B_o = {(tAMB_B + delB), 2'b0} / FRAME_PIX; // 6 -> 8 bit
			next_tAMB_R = 32'd0;
			next_tAMB_G = 32'd0;
			next_tAMB_B = 32'd0;
		end
	end

	always@(*) begin 			// mFD^2 (mean)
		next_mFDs2 = mFDs2;
		next_tFDs2 = tFDs2;
		if((syncX_i != 10'd639)&&(syncY_i != 10'd479)) begin
			// add FD^2
			next_tFDs2 = tFDs2 + FDs2;
		end
		else begin
			// averge FD^2 
			next_mFDs2 = (tFDs2 + FDs2) / FRAME_PIX;
			next_tFDs2 = 32'd0;
		end
	end

	always@(*) begin 			// Deviation^2
		next_Devs2 = Devs2;
		next_tDev = tDev;
		if((syncX_i != 10'd639)&&(syncY_i != 10'd479)) begin
			// add (FD^2)^2
			next_tDev = tDev + FDs2*FDs2;
		end
		else begin
			// Dev^2 = sig(.^2)/N - M.^2  [ .= FD^2 ]
			next_Devs2 = (tDev + FDs2*FDs2) / FRAME_PIX - mFDs2*mFDs2;
			next_tDev = 64'd0;
		end
	end

	always@(*) begin 			// caculate Thershold
		next_thershold_o = mFDs2;// + 2*sqr(Devs2);
	end

//==== sequential part ======================================
	always@( posedge clk_25 or negedge reset ) begin
		if(reset == 0 ) begin
			AMB_SHIFT_R_o 		<= 8'd0;
			AMB_SHIFT_G_o 		<= 8'd0;
			AMB_SHIFT_B_o 		<= 8'd0;
			thershold_o 		<= 32'd0;

			tAMB_R 				<= 32'd0;
			tAMB_G 				<= 32'd0;
			tAMB_B 				<= 32'd0;

			tFDs2 				<= 32'd0;
			mFDs2 				<= 32'd0;

			tDev 				<= 64'd0;
			Devs2 				<= 64'd0;
		end
		else begin
			AMB_SHIFT_R_o 		<= next_AMB_SHIFT_R_o;
			AMB_SHIFT_G_o 		<= next_AMB_SHIFT_G_o;
			AMB_SHIFT_B_o 		<= next_AMB_SHIFT_B_o;
			thershold_o 		<= next_thershold_o;

			tAMB_R 				<= next_tAMB_R;
			tAMB_G 				<= next_tAMB_G;
			tAMB_B 				<= next_tAMB_B;

			tFDs2 				<= next_tFDs2;
			mFDs2 				<= next_mFDs2;

			tDev 				<= next_tDev;
			Devs2 				<= next_Devs2;
		end
	end

endmodule
