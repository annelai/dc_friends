module COUNTER(
    iCLK,
    iRST,
    iSIGNAL,
    oCOUNT
);

input iCLK, iRST, iSIGNAL;
output  [9:0]   oCOUNT;
reg     [9:0]   oCOUNT;
wire    [9:0]   next_oCOUNT;

assign  next_oCOUNT = iSIGNAL ? oCOUNT + 10'd1 : 10'd0;

always@(posedge iCLK or negedge iRST) begin
    if( ~iRST ) begin
        oCOUNT = 10'd0;
    end
    else begin
        oCOUNT = next_oCOUNT;
    end
end

endmodule