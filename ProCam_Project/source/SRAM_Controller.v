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
	iFIFO_ReadUsedw,
	iFIFO_Q,
	oFIFO_ReadRequest,
	oFIFO_ReadCLK,

	// enable signal
	iDVI_DVAL,

	// SRAM side
	oSRAM_WE,
	oSRAM_ADDR,
	ioSRAM_DQ,

	// clock source 125MHz
	iCLK,
	iHGCLK,
	iRST,

	oRespondToHG,

	oDEBUG

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
input	[9:0]	iFIFO_ReadUsedw;
input	[35:0]	iFIFO_Q;
output			oFIFO_ReadRequest;
output			oFIFO_ReadCLK;

// enable signal
input			iDVI_DVAL;

// SRAM side
output			oSRAM_WE;
output	[19:0]	oSRAM_ADDR;
inout	[15:0]	ioSRAM_DQ;

// clock source 125MHz
input			iCLK;
input			iHGCLK;
input			iRST;

// debug
output			oRespondToHG;
output	[9:0]	oDEBUG;


// -----------------------------------------------------------
// parameter declaration
// -----------------------------------------------------------
parameter	FRAME_WIDTH = 640;
parameter	FRAME_HEIGHT = 480;


// -----------------------------------------------------------
// reg/wire declaration
// -----------------------------------------------------------
reg				writeToSRAM,
				nextWriteToSRAM;
reg				prev_HGRequest;
reg				HGRequest_buf;

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

reg		[2:0]	clockCounter,
				nextClockCounter;

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

assign	oDEBUG = CCD_X;

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
	nextSRAM_ADDR = (nextWriteToSRAM)? CCD_Address:Read_Address;
	nextSRAM_WE = writeToSRAM;
end

always@(*)
begin
	if (iHGRequest)
		nextReady = 1'b1;
	else
		nextReady = 1'b0;
end

always@(*)
begin
	if (iHGRequest)
	begin
		// edge detector
		nextWriteToSRAM = 1'b0;
		nextFIFO_ReadRequest = 1'b0;
	end
	
	else if (iFIFO_ReadUsedw != 10'd0 && ~iDVI_DVAL)
	begin
		// FIFO is not empty
		nextWriteToSRAM = 1'b1;
		nextFIFO_ReadRequest = 1'b1;
	end

	else
	begin
		nextWriteToSRAM = 1'b0;
		nextFIFO_ReadRequest = 1'b0;
	end
end


// -----------------------------------------------------------
// Sequential Logic
// -----------------------------------------------------------
always@(posedge iCLK or negedge iRST)
begin
	if (!iRST)
	begin
		prev_HGRequest		<= 1'b0;
		HGRequest_buf 		<= 1'b0;
		oSRAM_ADDR			<= 20'd0;
		oSRAM_WE			<= 1'b0;
		oReady				<= 1'b0;
		oHGRed				<= 5'd0;
		oHGGreen			<= 6'd0;
		oHGBlue				<= 5'd0;
		oFIFO_ReadRequest	<= 1'b0;
		clockCounter		<= 3'd0;
		writeToSRAM			<= 1'b0;
	end

	else
	begin
		prev_HGRequest		<= HGRequest_buf;
		HGRequest_buf 		<= iHGRequest;
		oSRAM_ADDR 			<= nextSRAM_ADDR;
		oSRAM_WE			<= nextSRAM_WE;
		oReady				<= nextReady;
		oHGRed				<= nextToHGRed;
		oHGGreen			<= nextToHGGreen;
		oHGBlue				<= nextToHGBlue;
		oFIFO_ReadRequest	<= nextFIFO_ReadRequest;
		clockCounter		<= nextClockCounter;
		writeToSRAM			<= nextWriteToSRAM;
	end
end

endmodule
