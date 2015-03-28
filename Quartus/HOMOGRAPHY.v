module HOMOGRAPHY(
	iCLK,
	iRST_N,
	// SRAM
	iR,
	iG,
	iB,
	iREADY,
	oREQ,
	oSRAM_X,
	oSRAM_Y,
	// CONTROLLER
	iX,
	iY,
	iSTART,
	oCON_X,
	oCON_Y,
	oR,
	oG,
	oB,
	oREADY
);

/**	H00 H01 H02
 *	H10 H11 H12 / H_DEN
 *	H20 H21 H22
 */
parameter	H00		= 10'd1;
parameter	H01		= 10'd0;
parameter	H02		= 10'd0;

parameter	H10		= 10'd0;
parameter	H11		= 10'd1;
parameter	H12		= 10'd0;

parameter	H20		= 10'd0;
parameter	H21		= 10'd0;
parameter	H22		= 10'd1;
parameter	H_DEN	= 10'd1;

parameter 	S_IDLE	= 2'd0;
parameter	S_HOM	= 2'd1;
parameter	S_REQ	= 2'd2;
parameter	S_OUT	= 2'd3;

input iCLK, iRST_N, iREADY, iSTART;
input	[9:0]	iX, iY;
input	[4:0]	iR, iB;
input	[5:0] 	iG;

output	oREQ, oREADY;
output	[9:0]	oSRAM_X, oSRAM_Y, oCON_X, oCON_Y;
output	[4:0]	oR, oB;
output	[5:0]	oG;

reg	[1:0]	state, next_state;
reg oREQ, oREADY, next_oREQ, next_oREADY;
reg	[9:0]	oSRAM_X, oSRAM_Y, oCON_X, oCON_Y, next_oSRAM_X, next_oSRAM_Y, next_oCON_X, next_oCON_Y, denum;
reg	[4:0]	oR, oB, next_oR, next_oB;
reg	[5:0]	oG, next_oG;

always@(*) begin
	next_state = state;
	case( state )
		S_IDLE: begin
			if( iSTART ) begin
				next_state = S_HOM;
			end
		end
		S_HOM: begin
			next_state = S_REQ;
		end
		S_REQ: begin
			if( iREADY ) begin
				next_state = S_OUT;
			end
		end
		S_OUT: begin
			next_state = S_IDLE;
		end
		default: begin
			next_state = S_IDLE;
		end
	endcase
end

always@(*) begin
	next_oREQ = oREQ;
	next_oREADY = oREADY;
	next_oSRAM_X = oSRAM_X;
	next_oSRAM_Y = oSRAM_Y;
	next_oCON_X = oCON_X;
	next_oCON_Y = oCON_Y;
	next_oR = oR;
	next_oB = oB;
	next_oG = oG;
	denum = 0;
	case( state )
		S_IDLE: begin
			next_oREQ = 1'd0;
			next_oREADY = 1'd0;
		end
		S_HOM: begin
			next_oREQ = 1'd1;
			denum = H20 * iX + H21 * iY + H22;
			next_oCON_X = iX;
			next_oCON_Y = iY;
			next_oSRAM_X = ( H00 * iX + H01 * iY + H02 ) / denum;
			next_oSRAM_Y = ( H10 * iX + H11 * iY + H12 ) / denum;
		end
		S_REQ: begin
			next_oREQ = 1'd0;
		end
		S_OUT: begin
			next_oREADY = 1'd1;
			next_oR = iR;
			next_oG = iG;
			next_oB = iB;
		end
		default: begin
		end
	endcase
end

    always @(posedge iCLK or negedge iRST_N) begin
	    if( ~iRST_N ) begin
		    state	<= S_IDLE;
		    oREQ	<= 1'd0;
		    oREADY	<= 1'd0;
		    oSRAM_X	<= 10'd0;
		    oSRAM_Y	<= 10'd0;
		    oCON_X	<= 10'd0;
		    oCON_Y	<= 10'd0;
		    oR		<= 5'd0;
		    oG		<= 6'd0;
		    oB		<= 5'd0;
	    end
	    else begin
		    state	<= next_state;
		    oREQ	<= next_oREQ;
		    oREADY	<= next_oREADY;
		    oSRAM_X	<= next_oSRAM_X;
		    oSRAM_Y	<= next_oSRAM_Y;
		    oCON_X	<= next_oCON_X;
		    oCON_Y	<= next_oCON_Y;
		    oR		<= next_oR;
		    oG		<= next_oG;
		    oB		<= next_oB;
	    end
    end
endmodule
