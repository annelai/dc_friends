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
	// FIFO side
	q,
	rdempty,
	rdclk,
	rdreq,
	// Homography side
	return_x,
	return_y,
	r,
	g,
	b,
	ready,
	query_x,
	query_y,
	start,
	debug
);

// ==== parameter definition ===============================
	// finite state machine
	parameter S_IDLE = 1'b0;
	parameter S_WAIT = 1'b1;

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
	// FIFO side
	input 	[43:0] 	q; // 10,10,8,8,8
	input 			rdempty;
	
	output 			rdclk;
	output			rdreq;
	// Homography side
	input	[9:0]	return_x;
	input	[9:0]	return_y;
	input	[4:0]	r;
	input	[5:0]	g;
	input	[4:0]	b;
	input			ready;

	output	[9:0]	query_x;
	output	[9:0]	query_y;
	output			start;

	output 			debug;
// ==== reg/wire declaration ===============================
	wire 			rdclk;
	wire	[9:0]	x;
	wire	[9:0]	y;
	reg		[1:0]	state, next_state;

	reg		[4:0]	dvi_r;
	reg		[5:0]	dvi_g;
	reg		[4:0]	dvi_b;
	reg		[4:0]	ccd_r;
	reg		[5:0]	ccd_g;
	reg		[4:0]	ccd_b;
	reg		[4:0]	next_dvi_r;
	reg		[5:0]	next_dvi_g;
	reg		[4:0]	next_dvi_b;
	reg		[4:0]	next_ccd_r;
	reg		[5:0]	next_ccd_g;
	reg		[4:0]	next_ccd_b;

	reg 			rdreq, next_rdreq;

	reg 			start, next_start;
	reg		[9:0]	query_x;
	reg		[9:0]	query_y;
	reg		[9:0]	sync_x;
	reg		[9:0]	sync_y;
	reg		[9:0]	next_query_x;
	reg		[9:0]	next_query_y;
	reg		[9:0]	next_sync_x;
	reg		[9:0]	next_sync_y;
    
    reg             val, next_val;
	reg				debug, next_debug;

    reg     [35:0]  buffer1, buffer2, buffer3, buffer4, buffer5; // 10,10,5,6,5
    reg     [35:0]  next_buffer1, next_buffer2, next_buffer3, next_buffer4, next_buffer5;
    
// ==== combinational part =================================
	assign rdclk = clk_25;
	assign x = next_query_x;
	assign y = next_query_y;
    
    always@(*) begin
		next_state = state;
		next_query_x = query_x;
		next_query_y = query_y;
		next_dvi_r = dvi_r;
		next_dvi_g = dvi_g;
		next_dvi_b = dvi_b;
		next_ccd_r = ccd_r;
		next_ccd_g = ccd_g;
		next_ccd_b = ccd_b;

		next_sync_x = sync_x;
		next_sync_y = sync_y;
		next_rdreq = 1'b0;
		next_start = 1'b0;

        next_val = 1'b0;
		next_debug = 1'b0 || debug;

        next_buffer1 = 36'd0;
        next_buffer2 = buffer1;
        next_buffer3 = buffer2;
        next_buffer4 = buffer3;
        next_buffer5 = buffer4;
		
        case(state)
			S_IDLE: begin
				if(rdempty==1'b0) begin
					next_state = S_WAIT;
                    next_rdreq = 1'b1;
				end
			end
			S_WAIT: begin
                if(rdreq==1'b1) begin
					next_query_x = q[43:34];
					next_query_y = q[33:24];
					next_dvi_r = q[23:19];
					next_dvi_g = q[15:10];
					next_dvi_b = q[7:3];
                    next_buffer1 = {q[43:24], q[23:19], q[15:10], q[7:3]};
					next_start = 1'b1;
                end
				if(ready==1'b1) begin
                    next_val = 1'b1;
                    next_sync_x = buffer5[35:26];
                    next_sync_y = buffer5[25:16];
                    next_ccd_r = r;
                    next_ccd_g = g;
                    next_ccd_b = b;
                    next_dvi_r = buffer5[15:11];
                    next_dvi_g = buffer5[10:5];
                    next_dvi_b = buffer5[4:0];
                    if(buffer5[35:26]!=return_x || buffer5[25:16]!=return_y) begin
                        next_debug = 1'b1;
                    end
                    next_rdreq = 1'b1;
                    if(rdempty==1'b0) begin
                        next_state = S_IDLE;
                        next_rdreq = 1'b0;
                    end
				end
			end
		endcase
	end
    
// ==== sequential part ====================================
	always@(posedge clk_25 or negedge rst_n) begin
		if(rst_n==0) begin
			state 		<= S_IDLE;
			dvi_r		<= 5'd0;
			dvi_g		<= 6'd0;
			dvi_b		<= 5'd0;
			ccd_r		<= 5'd0;
			ccd_g		<= 6'd0;
			ccd_b		<= 5'd0;
			rdreq 		<= 1'b0;
			start 		<= 1'b0;
			query_x 	<= 10'd0;
			query_y 	<= 10'd0;
			sync_x 		<= 10'd0;
			sync_y 		<= 10'd0;
            debug       <= 1'b0;
            val         <= 1'b0;
            buffer1     <= 36'd0;
            buffer2     <= 36'd0;
            buffer3     <= 36'd0;
            buffer4     <= 36'd0;
            buffer5     <= 36'd0;
		end
		else begin
			state 		<= next_state;
			dvi_r		<= next_dvi_r;
			dvi_g		<= next_dvi_g;
			dvi_b		<= next_dvi_b;
			ccd_r		<= next_ccd_r;
			ccd_g		<= next_ccd_g;
			ccd_b		<= next_ccd_b;
			rdreq 		<= next_rdreq;
			start 		<= next_start;		
			query_x 	<= next_query_x;
			query_y 	<= next_query_y;
			sync_x 		<= next_sync_x;
			sync_y 		<= next_sync_y;
            debug       <= next_debug;
            val         <= next_val;
            buffer1     <= next_buffer1;
            buffer2     <= next_buffer2;
            buffer3     <= next_buffer3;
            buffer4     <= next_buffer4;
            buffer5     <= next_buffer5;
		end
	end
endmodule
