// -----------------------------------------------------------
// VGAController.v
// -----------------------------------------------------------
//
// Major Function:
//		Display VGA signal.
//
// -----------------------------------------------------------
//
// Created on 2015/03/06 by Alex Chiu.
//
// -----------------------------------------------------------

module VGAController(
	iRed,
	iGreen,
	iBlue,
	oRequestX,
	oRequestY,
	iCLK,
	iRST,

	oRED,
	oGREEN,
	oBLUE,
	oDESYNC,
	oHSYNC,
	oVSYNC,
	oSYNC,
	oBLANK,
	
	oHVCounter
	);
`include "VGA_Param.h"

// -----------------------------------------------------------
// input/output declaration
// -----------------------------------------------------------
input	[7:0]	iRed,
				iGreen,
				iBlue;

output	[11:0]	oRequestX,
				oRequestY;

input			iCLK,
				iRST;

output	[7:0]	oRED,
				oGREEN,
				oBLUE;

output			oDESYNC,
				oHSYNC,
				oVSYNC,
				oSYNC,
				oBLANK;
output	[11:0]	oHVCounter;

// -----------------------------------------------------------
// parameter declaration
// -----------------------------------------------------------
//`ifdef VGA_640x480p60
//	Horizontal Parameter	( Pixel )
parameter	H_SYNC_CYC	=	96;
parameter	H_SYNC_BACK	=	48;
parameter	H_SYNC_ACT	=	640;	
parameter	H_SYNC_FRONT=	16;
parameter	H_SYNC_TOTAL=	800;

//	Virtical Parameter		( Line )
parameter	V_SYNC_CYC	=	2;
parameter	V_SYNC_BACK	=	33;
parameter	V_SYNC_ACT	=	480;	
parameter	V_SYNC_FRONT=	10;
parameter	V_SYNC_TOTAL=	525; 


//`else
/*
// SVGA_800x600p60
//	Horizontal Parameter	( Pixel )
parameter	H_SYNC_CYC	=	128;
parameter	H_SYNC_BACK	=	88;
parameter	H_SYNC_ACT	=	800;	
parameter	H_SYNC_FRONT=	40;
parameter	H_SYNC_TOTAL=	1056;
//	Virtical Parameter		( Line )
parameter	V_SYNC_CYC	=	4;
parameter	V_SYNC_BACK	=	23;
parameter	V_SYNC_ACT	=	600;	
parameter	V_SYNC_FRONT=	1;
parameter	V_SYNC_TOTAL=	628;
*/
//`endif


//	Start Offset
parameter	X_START		=	H_SYNC_CYC+H_SYNC_BACK;
parameter	Y_START		=	V_SYNC_CYC+V_SYNC_BACK;

// Request offset
parameter 	REQUEST_OFFSET = 2;


// -----------------------------------------------------------
// reg/wire declaration
// -----------------------------------------------------------
reg 	[11:0]	X, nextX;
reg		[11:0]	Y, nextY;

reg 	[11:0]	HCounter,
				nextHCounter;
reg		[11:0]	VCounter,
				nextVCounter;

wire			HVAL;
wire			VVAL;
				
reg 	[7:0]	RED, GREEN, BLUE;
reg 			DESYNC,
				nextDESYNC;
reg 			HSYNC,
				nextHSYNC;
reg 			VSYNC,
				nextVSYNC;

reg 			SYNC;
wire			nextSYNC;

reg 			BLANK;
wire			nextBLANK;


// -----------------------------------------------------------
// Output assign
// -----------------------------------------------------------
assign	oRequestX = X;
assign	oRequestY = Y;
assign	oRED = (HVAL & VVAL)? RED:8'd0;
assign	oGREEN = (HVAL & VVAL)? GREEN:8'd0;
assign	oBLUE = (HVAL & VVAL)? BLUE:8'd0;
assign	oDESYNC = (HVAL & VVAL); //DESYNC;
assign	oHSYNC = HSYNC;
assign	oVSYNC = VSYNC;
assign	oSYNC = SYNC;
assign	oBLANK = BLANK;
assign	oHVCounter = VCounter;

assign 	nextBLANK = ~(nextHSYNC & nextVSYNC);
assign 	nextSYNC = 1'b0;

assign	HVAL = (HCounter >= X_START && HCounter < X_START + H_SYNC_ACT);
assign	VVAL = (VCounter >= Y_START && VCounter < Y_START + V_SYNC_ACT);

// -----------------------------------------------------------
// Combinational Logic
// -----------------------------------------------------------
/*// DESYNC generator
always@(*)
begin
	nextDESYNC = (HVAL & VVAL);
end*/
// HSYNC generator
always@(*)
begin
	if (HCounter < H_SYNC_TOTAL - 12'd1)
		nextHCounter = HCounter + 12'd1;
	else
		nextHCounter = 12'd0;

	if (HCounter == H_SYNC_TOTAL - 12'd1 || HCounter < H_SYNC_CYC - 12'd1)
		nextHSYNC = 0;
	else
		nextHSYNC = 1;
end

// VSYNC generator
always@(*)
begin
	if (HCounter == H_SYNC_TOTAL - 12'd1)
		nextVCounter = VCounter + 12'd1;
	else if (VCounter == V_SYNC_TOTAL - 12'd1)
		nextVCounter = 12'd0;
	else
		nextVCounter = VCounter;

	if (VCounter < V_SYNC_CYC)
		nextVSYNC = 0;
	else
		nextVSYNC = 1;
end

// X, Y request generator
always@(*)
begin
	if (HCounter >= X_START - REQUEST_OFFSET && HCounter < X_START + H_SYNC_ACT- REQUEST_OFFSET)
		nextX = X + 12'd1;
	else
		nextX = 12'd0;

	if (VCounter > Y_START && VCounter < Y_START + V_SYNC_ACT)
		if (HCounter == 12'd0)
			nextY = Y + 12'd1;
		else
			nextY = Y;
	else
		nextY = 12'd0;
end


// -----------------------------------------------------------
// Sequential Logic
// -----------------------------------------------------------
always@(posedge iCLK or negedge iRST)
begin
	if (!iRST)
	begin
		HCounter 	<= 12'd0;
		VCounter 	<= 12'd0;
		X 			<= 12'd0;
		Y 			<= 12'd0;
	end

	else
	begin
		HCounter 	<= nextHCounter;
		VCounter 	<= nextVCounter;
		X 			<= nextX;
		Y 			<= nextY;
	end
end

always@(posedge iCLK or negedge iRST)
begin
	if (!iRST)
	begin
		RED 	<= 8'h0;
		GREEN 	<= 8'h0;
		BLUE 	<= 8'h0;
		//DESYNC 	<= 1'b0;
		HSYNC 	<= 1'b0;
		VSYNC 	<= 1'b0;
		SYNC 	<= 1'b0;
		BLANK 	<= 1'b0;
	end

	else
	begin
		RED 	<= iRed;
		GREEN 	<= iGreen;
		BLUE 	<= iBlue;
		//DESYNC 	<= nextDESYNC;
		HSYNC 	<= nextHSYNC;
		VSYNC 	<= nextVSYNC;
		SYNC 	<= nextSYNC;
		BLANK 	<= nextBLANK;		
	end
end

endmodule

