module MASK(
	iCLK,
	iRST_N,

	// DVI
	iDVI_X,
	iDVI_Y,
	iDVI_R,
	iDVI_G,
	iDVI_B,

	// mask generator
	iMASK,
	iMASK_VAL,
	iMASK_X,
	iMASK_Y,

	// output
	oX,
	oY,
	oR,
	oG,
	oB,
	oVAL,
	oDEBUG
);

input	iCLK, iRST_N, iMASK, iMASK_VAL;
input	[9:0]	iDVI_X, iDVI_Y, iMASK_X, iMASK_Y;
input	[7:0]	iDVI_R, iDVI_G, iDVI_B;

output reg	[9:0]	oX, oY;
output reg	[7:0]	oR, oG, oB;
output reg	oDEBUG, oVAL;

reg	[9:0]	next_oX, next_oY;
reg	[7:0]	next_oR, next_oG, next_oB;
reg	next_oDEBUG, next_VAL;

always@(*) begin
	next_oDEBUG = 1'd0;
	if( iMASK_VAL ) begin
		next_oX = iMASK_X;
		next_oY = iMASK_Y;
		next_oVAL = 1'b1;
		if( iMASK ) begin
			next_oR = iDVI_R;
			next_oG = iDVI_G;
			next_oB = iDVI_B;
		end
		else begin
			next_oR = 8'd0;
			next_oG = 8'd0;
			next_oB = 8'd0;
		end
	end
	else begin
		next_oX = oX;
		next_oY = oY;
		next_oVAL = 1'b0;
		next_oR = oR;
		next_oG = oG;
		next_oB = oB;
	end
end

always@(posedge iCLK or negedge iRST_N) begin
	if( ~iRST_N ) begin
		oX		<= 10'd0;
		oY		<= 10'd0;
		oR		<= 8'd0;
		oG		<= 8'd0;
		oB		<= 8'd0;
		oVAL	<= 1'd0;
		oDEBUG	<= 1'd0;
	end
	    else begin
		oX		<= next_oX;
		oY		<= next_oY;
		oR		<= next_oR;
		oG		<= next_oG;
		oB		<= next_oB;
		oVAL	<= next_oVAL;
		oDEBUG	<= next_oDEBUG;
	    end
end

endmodule