module sync_controller (
	clk_25,
	rst_n,
    val,
	sync_x,
	sync_y,
	dvi_r,
	dvi_g,
	dvi_b,
	ccd_r,
	ccd_g,
	ccd_b,
	// ColorTransform side
	q,
	rdreq,
	// Homography side
	return_x,
	return_y,
	r,
	g,
	b,
	ready,
	debug
);

// ==== in/out declaration =================================
	input 			clk_25;
	input 			rst_n;
    
    output          val;
	output	[9:0]	sync_x;
	output	[9:0]	sync_y;
	output	[4:0]	dvi_r;
	output	[5:0]	dvi_g;
	output	[4:0]	dvi_b;
	output	[4:0]	ccd_r;
	output	[5:0]	ccd_g;
	output	[4:0]	ccd_b;
	// ColorTransform side
	input 	[43:0] 	q; // 10,10,8,8,8
	input 			rdreq;
	// Homography side
	input	[9:0]	return_x;
	input	[9:0]	return_y;
	input	[4:0]	r;
	input	[5:0]	g;
	input	[4:0]	b;
	input			ready;
	output 			debug;
// ==== reg/wire declaration ===============================
	wire 			rdclk;

	reg		[4:0]	dvi_r, dvi_b, next_dvi_r, next_dvi_b;
	reg		[5:0]	dvi_g, next_dvi_g;
	reg		[4:0]	ccd_r, ccd_b, next_ccd_r, next_ccd_b;
	reg		[5:0]	ccd_g, next_ccd_g;

	reg		[9:0]	sync_x, sync_y, next_sync_x, next_sync_y;
    
    reg             val, next_val;
	reg				debug, next_debug;

    reg     [35:0]  buffer, next_buffer; // 10,10,5,6,5
// ==== combinational part =================================
    
    always@(*) begin
		next_dvi_r = dvi_r;
		next_dvi_g = dvi_g;
		next_dvi_b = dvi_b;
		next_ccd_r = ccd_r;
		next_ccd_g = ccd_g;
		next_ccd_b = ccd_b;

        next_val = 1'b0;
		next_sync_x = sync_x;
		next_sync_y = sync_y;

        next_buffer = buffer;
        next_debug = 1'b0 || debug;

        if(rdreq==1'b1) begin
            next_buffer = {q[43:24], q[23:19], q[15:10], q[7:3]};
        end
		
		if(ready==1'b1) begin
            next_val = 1'b1;
            next_ccd_r = r;
            next_ccd_g = g;
            next_ccd_b = b;
            
         	next_sync_x = buffer[35:26];
         	next_sync_y = buffer[25:16];
         	next_dvi_r = buffer[15:11];
         	next_dvi_g = buffer[10:5];
         	next_dvi_b = buffer[4:0];
			
            if(next_sync_x!=return_x || next_sync_y!=return_y) next_debug = 1'b1;
		end
	end

    
// ==== sequential part ====================================
	always@(posedge clk_25 or negedge rst_n) begin
		if(rst_n==0) begin
			dvi_r		<= 5'd0;
			dvi_g		<= 6'd0;
			dvi_b		<= 5'd0;
			ccd_r		<= 5'd0;
			ccd_g		<= 6'd0;
			ccd_b		<= 5'd0;
			sync_x 		<= 10'd0;
			sync_y 		<= 10'd0;
            debug       <= 1'b0;
            val         <= 1'b0;
            buffer      <= 36'd0;
		end
		else begin
			dvi_r		<= next_dvi_r;
			dvi_g		<= next_dvi_g;
			dvi_b		<= next_dvi_b;
			ccd_r		<= next_ccd_r;
			ccd_g		<= next_ccd_g;
			ccd_b		<= next_ccd_b;
			sync_x 		<= next_sync_x;
			sync_y 		<= next_sync_y;
            debug       <= next_debug;
            val         <= next_val;
            buffer      <= next_buffer;
		end
	end
endmodule
