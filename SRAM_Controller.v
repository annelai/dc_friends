// -----------------------------------------------------------
// SRAM_Controller.v
// -----------------------------------------------------------
//
// Major Function:
//		Control SRAM port.
//
// -----------------------------------------------------------
//
// Created on 2015/03/19 by Alex Chiu.
//
// -----------------------------------------------------------

module SRAM_Controller(
	// Homography side
	iHGRequest,
	iHGX,
	iHGY,
	oHGRed,
	oHGGreen,
	oHGBlue,
	oReady,

	// CCD FIFO side
	iFIFO_ReadEmpty,
	iFIFO_Q,
	oFIFO_ReadRequest,
	oFIFO_ReadCLK,

	// SRAM side
	oSRAM_WE,
	oSRAM_ADDR,
	ioSRAM_DQ,

	// clock source 125MHz
	iCLK,
	iHGCLK,
	iRST

	);

// -----------------------------------------------------------
// input/output declaration
// -----------------------------------------------------------

// Homography side
input			iHGRequest;
input	[9:0]	iHGX;
input	[9:0] 	iHGY;
output 	[4:0]	oHGRed;
output	[5:0]	oHGGreen;
output	[4:0]	oHGBlue;
output			oReady;

// CCD FIFO side
input			iFIFO_ReadEmpty;
input	[35:0]	iFIFO_Q;
output			oFIFO_ReadRequest;
output			oFIFO_ReadCLK;

// SRAM side
output			oSRAM_WE;
output	[19:0]	oSRAM_ADDR;
inout	[15:0]	ioSRAM_DQ;

// clock source 125MHz
input			iCLK;
input			iHGCLK;
input			iRST;


// -----------------------------------------------------------
// parameter declaration
// -----------------------------------------------------------
parameter	FRAME_WIDTH = 640;
parameter	FRAME_HEIGHT = 480;


// -----------------------------------------------------------
// reg/wire declaration
// -----------------------------------------------------------
reg				writeToSRAM;
reg				prev_HGCLK;

reg		[19:0]	CCD_Address;
wire	[9:0]	CCD_X, CCD_Y;
wire	[4:0]	CCD_Red, CCD_Blue;
wire	[5:0]	CCD_Green;

reg 	[19:0]	Read_Address;

reg		[19:0]	oSRAM_ADDR,
				nextSRAM_ADDR;
reg				oSRAM_WE, nextSRAM_WE;

reg				oReady,
				nextReady;

reg		[4:0]	oHGRed,
				nextToHGRed,
				oHGBlue,
				nextToHGBlue;
reg		[5:0]	oHGGreen,
				nextToHGGreen;

reg				oFIFO_ReadRequest,
				nextFIFO_ReadRequest;


// -----------------------------------------------------------
// Combinational Logic
// -----------------------------------------------------------
assign	oFIFO_ReadCLK = iCLK;// TO BE SURE
assign	ioSRAM_DQ = (writeToSRAM)? iFIFO_Q[15:0]:16'bz;

assign	CCD_X = iFIFO_Q[35:26];
assign	CCD_Y = iFIFO_Q[25:16];

assign	CCD_Red = iFIFO_Q[15:11];
assign	CCD_Green = iFIFO_Q[10:5];
assign	CCD_Blue = iFIFO_Q[4:0];

always@(*)
begin
	CCD_Address = CCD_Y * FRAME_WIDTH + CCD_X;
end

always@(*)
begin
	Read_Address = iHGY * FRAME_WIDTH + iHGX;
end

always@(*)
begin
	if (oReady)
	begin
		nextToHGRed = ioSRAM_DQ[15:11];
		nextToHGGreen = ioSRAM_DQ[10:5];
		nextToHGBlue = ioSRAM_DQ[4:0];
	end

	else
	begin
		nextToHGRed = oHGRed;
		nextToHGGreen = oHGGreen;
		nextToHGBlue = oHGBlue;
	end
end

always@(*)
begin
	nextSRAM_ADDR = (writeToSRAM)? CCD_Address:Read_Address;
	nextSRAM_WE = writeToSRAM;
end

/*
always@(*)
begin
	nextClockCounter = (clockCounter == 3'd4)? 3'd0:(clockCounter+3'd1);
end
*/

always@(*)
begin
	if (iHGRequest && ({prev_HGCLK,iHGCLK} == 2'b01))
	begin
		// edge detector
		writeToSRAM = 1'b0;
		nextFIFO_ReadRequest = 1'b0;
		nextReady = 1'b1;
	end
	
	else if (!iFIFO_ReadEmpty)
	begin
		// FIFO is not empty
		writeToSRAM = 1'b1;
		nextFIFO_ReadRequest = 1'b1;
		nextReady = 1'b0;
	end

	else
	begin
		// FIFO is empty, should not be this case though
		writeToSRAM = 1'b0;
		nextFIFO_ReadRequest = 1'b0;
		nextReady = 1'b0;
	end
end


// -----------------------------------------------------------
// Sequential Logic
// -----------------------------------------------------------
always@(posedge iCLK or negedge iRST)
begin
	if (!iRST)
	begin
		prev_HGCLK		<= 1'b0;
		oSRAM_ADDR		<= 20'd0;
		oSRAM_WE		<= 1'b0;
		oReady			<= 1'b0;
		oHGRed			<= 5'd0;
		oHGGreen		<= 6'd0;
		oHGBlue			<= 5'd0;
		oFIFO_ReadRequest	<= 1'b0;
	end

	else
	begin
		prev_HGCLK		<= iHGCLK;
		oSRAM_ADDR 		<= nextSRAM_ADDR;
		oSRAM_WE		<= nextSRAM_WE;
		oReady			<= nextReady;
		oHGRed			<= nextToHGRed;
		oHGGreen		<= nextToHGGreen;
		oHGBlue			<= nextToHGBlue;
		oFIFO_ReadRequest	<= nextFIFO_ReadRequest;
	end
end


endmodule

