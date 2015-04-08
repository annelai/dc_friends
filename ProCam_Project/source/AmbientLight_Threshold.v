module ALT (
	// input port //
	clk_pixl,
	clk_frame,
	reset,
	//// input data ////
	valid_i,
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
	mean_o,
	covar_o
);

//==== parameter definition =================================
	parameter FRAME_PIX	= 32'd307200; // = 640*480  

//==== in/out declaration ===================================
	//---- input ----//
	input clk_pixl;
	input clk_frame;
	input reset;

	input valid_i;
	input [9:0] syncX_i, syncY_i;
	input [4:0] DVI_R_i, DVI_B_i;
	input [5:0] DVI_G_i;
	input [4:0] CCD_R_i, CCD_B_i;
	input [5:0] CCD_G_i;
	//---- output ----//
	output [7:0] AMB_SHIFT_R_o, AMB_SHIFT_G_o, AMB_SHIFT_B_o;
	output [31:0] mean_o;
	output [63:0] covar_o;

//==== reg/wire declaration =================================
	//---- output ----//
	reg [7:0] AMB_SHIFT_R_o, AMB_SHIFT_G_o, AMB_SHIFT_B_o;
	reg [7:0] next_AMB_SHIFT_R_o, next_AMB_SHIFT_G_o, next_AMB_SHIFT_B_o;
	reg [31:0] mean_o, next_mean_o;
	reg [63:0] covar_o, next_covar_o;

	//---- wire ----//
	reg [5:0]	delR, next_delR, 
				delG, next_delG,
				delB, next_delB;
	reg [7:0] 	amb_SHIFT_R, amb_SHIFT_G, amb_SHIFT_B,
			 	next_amb_SHIFT_R, next_amb_SHIFT_G, next_amb_SHIFT_B;

	reg [31:0]	FDs2_R, next_FDs2_R,
				FDs2_G, next_FDs2_G,
				FDs2_B, next_FDs2_B;
	reg [31:0] FDs2, next_FDs2;
	//---- flip-flops ----//
	reg [9:0] syncX, syncY,
			  next_syncX, next_syncY;
	reg [5:0] DVI_R, DVI_G, DVI_B,
			  next_DVI_R, next_DVI_G, next_DVI_B;
	reg [5:0] CCD_R, CCD_G, CCD_B,
			  next_CCD_R, next_CCD_G, next_CCD_B;


	reg [31:0] tAMB_R, tAMB_G, tAMB_B;
	reg [31:0] next_tAMB_R, next_tAMB_G, next_tAMB_B; 
	reg [31:0] tFDs2, next_tFDs2;	//gradually accumulate FDs2
	reg [63:0] mFDs2, next_mFDs2;	//full FDs2
	reg [31:0] MFDs2, next_MFDs2;	//mean FDs2 : MFD^2 = mFD^2/FRAME
	reg [63:0] tDev, next_tDev;		//gradually accumulate Devs2
	reg [63:0] devs2, next_devs2;	//full Devs2
	reg [63:0] Devs2, next_Devs2;	//covariance = dev^2/FRAME - MFD^2*MFD^2
//==== combinational part ===================================
	always@(*) begin
		next_syncX = syncX; 
		next_syncY = syncY;
		next_DVI_R = DVI_R;
		next_DVI_G = DVI_G; 
		next_DVI_B = DVI_B;
		next_CCD_R = CCD_R;
		next_CCD_G = CCD_G; 
		next_CCD_B = CCD_B;
		if(valid_i) begin
			next_syncX = syncX_i; 
			next_syncY = syncY_i;
			next_DVI_R = {DVI_R_i, 1'b0};
			next_DVI_G = DVI_G_i; 
			next_DVI_B = {DVI_B_i, 1'b0};
			next_CCD_R = {CCD_R_i, 1'b0};
			next_CCD_G = CCD_G_i; 
			next_CCD_B = {CCD_B_i, 1'b0};
		end
	end

	// absolute difference
	always@(*) begin
		next_delR = (DVI_R > CCD_R) ? (DVI_R - CCD_R) : (CCD_R - DVI_R);
		next_delG = (DVI_G > CCD_G) ? (DVI_G - CCD_G) : (CCD_G - DVI_G);
		next_delB = (DVI_B > CCD_B) ? (DVI_B - CCD_B) : (CCD_B - DVI_B);	
	end
	
	// FD^2 = (dR^2 + dG^2 + dB^2)
	always@(*) begin
		next_FDs2_R = delR*delR;
		next_FDs2_G = delG*delG;
		next_FDs2_B = delB*delB;
	end
	always@(*) begin
		next_FDs2 = FDs2_R + FDs2_G + FDs2_B;
	end

	// frame done 640*480 output
	always@(*) begin 			// Ambient Light Shift (mean)	
		next_amb_SHIFT_R = amb_SHIFT_R;
		next_amb_SHIFT_G = amb_SHIFT_G;
		next_amb_SHIFT_B = amb_SHIFT_B;

		next_tAMB_R = tAMB_R;
		next_tAMB_G = tAMB_G;
		next_tAMB_B = tAMB_B;

		if((syncX != 10'd639)&&(syncY != 10'd479)) begin
			// 	add AMB
			next_tAMB_R = tAMB_R + delR; // 6 bit
			next_tAMB_G = tAMB_G + delG; // 6 bit						
			next_tAMB_B = tAMB_B + delB; // 6 bit 
		end
		else begin 	
			// averge AMB
			next_amb_SHIFT_R = {(tAMB_R + delR), 2'b0}; // 6 -> 8 bit
			next_amb_SHIFT_G = {(tAMB_G + delG), 2'b0}; // 6 -> 8 bit
			next_amb_SHIFT_B = {(tAMB_B + delB), 2'b0}; // 6 -> 8 bit
			next_tAMB_R = 32'd0;
			next_tAMB_G = 32'd0;
			next_tAMB_B = 32'd0;
		end
	end
	always@(*) begin
		next_AMB_SHIFT_R_o 	= amb_SHIFT_R / FRAME_PIX;
		next_AMB_SHIFT_G_o 	= amb_SHIFT_G / FRAME_PIX;
		next_AMB_SHIFT_B_o 	= amb_SHIFT_B / FRAME_PIX;
	end

	always@(*) begin 			// mFD^2 (mean)
		next_mFDs2 = mFDs2;
		next_tFDs2 = tFDs2;
		if((syncX != 10'd639)&&(syncY != 10'd479)) begin
			// add FD^2
			next_tFDs2 = tFDs2 + FDs2;
		end
		else begin
			// full FD^2 (640*480) 
			next_mFDs2 = (tFDs2 + FDs2);
			next_tFDs2 = 32'd0;
		end
	end
	always@(*) begin
		next_MFDs2 = mFDs2 / FRAME_PIX;
	end

	always@(*) begin 			// Deviation^2
		next_devs2 = devs2;
		next_tDev = tDev;
		if((syncX != 10'd639)&&(syncY != 10'd479)) begin
			// add (FD^2)^2
			next_tDev = tDev + FDs2*FDs2;
		end
		else begin
			// Dev^2 = sig(.^2)/N - M.^2  [ .= FD^2 ]
			next_devs2 = (tDev + FDs2*FDs2);
			next_tDev = 64'd0;
		end
	end
	always@(*) begin
		next_Devs2 = devs2 / FRAME_PIX;
	end

	always@(*) begin 			// caculate threshold = mean + 2*sqrt(Devs2)
		next_mean_o = MFDs2;// + 2*sqr(Devs2);
	end
	always@(*) begin
		next_covar_o = Devs2 - MFDs2*MFDs2;
	end

//==== sequential part ======================================
	always@( posedge clk_pixl or negedge reset ) begin
		if(reset == 0 ) begin
			amb_SHIFT_R 		<= 8'd0;
			amb_SHIFT_G 		<= 8'd0;
			amb_SHIFT_B 		<= 8'd0;
			mean_o 				<= 32'd0;
			covar_o 			<= 64'd0;

			syncX 				<= 10'd0;
			syncY 				<= 10'd0;
			DVI_R 				<= 6'd0;
			DVI_G 				<= 6'd0;
			DVI_B 				<= 6'd0;
			CCD_R 				<= 6'd0;
			CCD_G 				<= 6'd0;
			CCD_B 				<= 6'd0;

			delR 				<= 6'd0;
			delG 				<= 6'd0;
			delB 				<= 6'd0;

			FDs2_R 				<= 32'd0;
			FDs2_G 				<= 32'd0;
			FDs2_B 				<= 32'd0; 
			FDs2 				<= 32'd0;

			tAMB_R 				<= 32'd0;
			tAMB_G 				<= 32'd0;
			tAMB_B 				<= 32'd0;

			tFDs2 				<= 32'd0;
			mFDs2 				<= 64'd0;

			tDev 				<= 64'd0;
			devs2 				<= 64'd0;

		end
		else begin
			amb_SHIFT_R 		<= next_amb_SHIFT_R;
			amb_SHIFT_G 		<= next_amb_SHIFT_G;
			amb_SHIFT_B 		<= next_amb_SHIFT_B;
			mean_o 				<= next_mean_o;
			covar_o 			<= next_covar_o;

			syncX 				<= next_syncX; 				
			syncY 				<= next_syncY;
			DVI_R 				<= next_DVI_R;
			DVI_G 				<= next_DVI_G;
			DVI_B 				<= next_DVI_B;
			CCD_R 				<= next_CCD_R;
			CCD_G 				<= next_CCD_G;
			CCD_B 				<= next_CCD_B;

			delR 				<= next_delR;
			delG 				<= next_delG;
			delB 				<= next_delB;

			FDs2_R 				<= next_FDs2_R;
			FDs2_G 				<= next_FDs2_G;
			FDs2_B 				<= next_FDs2_B;
			FDs2 				<= next_FDs2;

			tAMB_R 				<= next_tAMB_R;
			tAMB_G 				<= next_tAMB_G;
			tAMB_B 				<= next_tAMB_B;

			tFDs2 				<= next_tFDs2;
			mFDs2 				<= next_mFDs2;

			tDev 				<= next_tDev;
			devs2 				<= next_devs2;
		end
	end
	always@( posedge clk_frame or negedge reset ) begin
		if(reset == 0 ) begin
			MFDs2 				<= 32'd0;
			Devs2 				<= 64'd0;
			AMB_SHIFT_R_o 		<= 8'd0;
			AMB_SHIFT_G_o 		<= 8'd0;
			AMB_SHIFT_B_o 		<= 8'd0;
		end
		else begin
			MFDs2 				<= next_MFDs2;
			Devs2 				<= next_Devs2;
			AMB_SHIFT_R_o 		<= next_AMB_SHIFT_R_o;
			AMB_SHIFT_G_o 		<= next_AMB_SHIFT_G_o;
			AMB_SHIFT_B_o 		<= next_AMB_SHIFT_B_o;
		end
	end
endmodule
