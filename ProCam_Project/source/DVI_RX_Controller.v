// -----------------------------------------------------------
// DVI_RX_Controller.v
// -----------------------------------------------------------
//
// Major Function:
//		Recieve DVI signal.
//
// -----------------------------------------------------------
//
// Created on 2015/04/02 by Alex Chiu.
//
// -----------------------------------------------------------

module DVI_RX_Controller(
	DVI_RX_CLK,
	DVI_RX_D,
	DVI_RX_DE,
	DVI_RX_HS,
	DVI_RX_VS,

	oX_Counter,
	oY_Counter,
	oDVAL,
	oDVI_CLK,
	oR,
	oG,
	oB
	);

// -----------------------------------------------------------
// input/output declaration
// -----------------------------------------------------------
input			DVI_RX_CLK;
input	[23:0]	DVI_RX_D;
input			DVI_RX_DE;
input			DVI_RX_HS;
input			DVI_RX_VS;

output	[11:0]	oX_Counter;
output	[11:0]	oY_Counter;
output			oDVAL;
output			oDVI_CLK;
output	[7:0]	oR;
output	[7:0]	oG;
output	[7:0]	oB;


// -----------------------------------------------------------
// parameter declaration
// -----------------------------------------------------------
//	Horizontal Parameter ( Pixel )
parameter	H_SYNC_CYC		=	96;
parameter	H_SYNC_BACK		=	48;
parameter	H_SYNC_ACT		=	640;	
parameter	H_SYNC_FRONT	=	16;
parameter	H_SYNC_TOTAL	=	800;

//	Virtical Parameter ( Line )
parameter	V_SYNC_CYC		=	2;
parameter	V_SYNC_BACK		=	33;
parameter	V_SYNC_ACT		=	480;
parameter	V_SYNC_FRONT	=	10;
parameter	V_SYNC_TOTAL	=	525; 

//	Start Offset
parameter	X_START		=	H_SYNC_BACK;
parameter	Y_START		=	V_SYNC_BACK;


// -----------------------------------------------------------
// reg/wire declaration
// -----------------------------------------------------------
reg		[11:0]	H_Counter,
				nextH_Counter,
				V_Counter,
				nextV_Counter;

reg		[11:0]	X_Counter,
				nextX_Counter,
				Y_Counter,
				nextY_Counter;

reg		[7:0]	oR, oG, oB;
reg			oDVAL;

wire 			DVAL;
wire	[7:0]	DATA_Red,
				DATA_Green,
				DATA_Blue;

// -----------------------------------------------------------
// Combinational Logic
// -----------------------------------------------------------
assign	oX_Counter = X_Counter;
assign	oY_Counter = Y_Counter;
assign	oDVI_CLK = ~DVI_RX_CLK;


assign	DVAL = (H_Counter >= X_START && H_Counter < X_START + H_SYNC_ACT) &&
			   (V_Counter >= Y_START && V_Counter < Y_START + V_SYNC_ACT);
assign	DATA_Red = DVI_RX_D[23:16];
assign	DATA_Green = DVI_RX_D[15:8];
assign	DATA_Blue = DVI_RX_D[7:0];


always@(*)
begin
	nextH_Counter = H_Counter + 12'd1;
	nextV_Counter = V_Counter + 12'd1;
end

always@(*)
begin
	if (H_Counter >= X_START && H_Counter < X_START + H_SYNC_ACT)
		nextX_Counter = X_Counter + 12'd1;
	else
		nextX_Counter = 12'd0;
end

always@(*)
begin
	if (V_Counter > Y_START && V_Counter < Y_START + V_SYNC_ACT)
		nextY_Counter = Y_Counter + 12'd1;
	else
		nextY_Counter = 12'd0;
end


// -----------------------------------------------------------
// Sequential Logic
// -----------------------------------------------------------
// Horizontal Counter
always@(negedge DVI_RX_CLK or negedge DVI_RX_HS)
begin
	if (!DVI_RX_HS)
	begin
		H_Counter		<= 12'd0;
		X_Counter		<= 12'd0;
		oDVAL			<= 1'b0;
		oR				<= 8'd0;
		oG				<= 8'd0;
		oB				<= 8'd0;
	end

	else
	begin
		H_Counter		<= nextH_Counter;
		X_Counter		<= nextX_Counter;
		oDVAL			<= DVAL;
		oR				<= DATA_Red;
		oG				<= DATA_Green;
		oB				<= DATA_Blue;
	end
end

// Vertical Counter
always@(posedge DVI_RX_HS or negedge DVI_RX_VS)
begin
	if (!DVI_RX_VS)
	begin
		V_Counter		<= 12'd0;
		Y_Counter		<= 12'd0;
	end

	else
	begin
		V_Counter		<= nextV_Counter;
		Y_Counter		<= nextY_Counter;
	end
end

/*
// Data Valid X
always@(negedge DVI_RX_CLK)
begin
	X_Counter			<= nextX_Counter;
end
*/

/*
// Data Valid Y
always@(posedge DVI_RX_HS)
begin
	Y_Counter			<= nextY_Counter;
end
*/

/*
// Data transfer
always@(negedge DVI_RX_CLK)
begin
	oDVAL	<= DVAL;
	oR		<= DATA_Red;
	oG		<= DATA_Green;
	oB		<= DATA_Blue;
end
*/

endmodule

