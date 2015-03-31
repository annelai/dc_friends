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
    reg     [2:0]   count, next_count;
    reg             max_count, next_max_count;
// ==== combinational part =================================
	assign rdclk = clk_25;
    
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
		next_start = 1'b1;

        next_val = 1'b0;

        next_buffer1 = buffer1; // buffer 1 >> 2 >> 3 >> 4 >> 5
        next_buffer2 = buffer2;
        next_buffer3 = buffer3;
        next_buffer4 = buffer4;
        next_buffer5 = buffer5;
        next_count = count;
        next_max_count = max_count;

        next_debug = 1'b0 || debug;

        case(state)
			S_IDLE: begin
                next_start = 1'b0;
				if(~rdempty) begin
					next_state = S_WAIT;
                    next_rdreq = 1'b1;
                end
			end
			S_WAIT: begin
                if(rdreq==1'b1) begin
					next_query_x = q[43:34];
					next_query_y = q[33:24];

                    next_buffer1 = {q[43:24], q[23:19], q[15:10], q[7:3]};
                    
                    if(max_count!=1'b1) begin
                        next_count = count + 3'd1;
                        next_buffer2 = buffer1;
                    	next_buffer3 = buffer2;
                    	next_buffer4 = buffer3;
                    	next_buffer5 = buffer4;
                    end
                end
                else begin
                    next_start = 1'b0;
                end

				if(ready==1'b1) begin
                    next_max_count = 1'b1;
                    next_val = 1'b1;
                    next_ccd_r = r;
                    next_ccd_g = g;
                    next_ccd_b = b;
                    
                    next_buffer2 = buffer1;
                    next_buffer3 = buffer2;
                    next_buffer4 = buffer3;
                    next_buffer5 = buffer4;
                    case(count)
                		3'd1: begin
                		    next_sync_x = buffer1[35:26];
                		    next_sync_y = buffer1[25:16];
                		    next_dvi_r = buffer1[15:11];
                		    next_dvi_g = buffer1[10:5];
                		    next_dvi_b = buffer1[4:0];
                		end
                		3'd2: begin
                		    next_sync_x = buffer2[35:26];
                		    next_sync_y = buffer2[25:16];
                		    next_dvi_r = buffer2[15:11];
                		    next_dvi_g = buffer2[10:5];
                		    next_dvi_b = buffer2[4:0];
                		end
                		3'd3: begin
                		    next_sync_x = buffer3[35:26];
                		    next_sync_y = buffer3[25:16];
                		    next_dvi_r = buffer3[15:11];
                		    next_dvi_g = buffer3[10:5];
                		    next_dvi_b = buffer3[4:0];
                		end
                		3'd4: begin
                		    next_sync_x = buffer4[35:26];
                		    next_sync_y = buffer4[25:16];
                		    next_dvi_r = buffer4[15:11];
                		    next_dvi_g = buffer4[10:5];
                		    next_dvi_b = buffer4[4:0];
                		end
                		3'd5: begin
                		    next_sync_x = buffer5[35:26];
                		    next_sync_y = buffer5[25:16];
                		    next_dvi_r = buffer5[15:11];
                		    next_dvi_g = buffer5[10:5];
                		    next_dvi_b = buffer5[4:0];
                		end
					endcase
					if(next_sync_x!=return_x || next_sync_y!=return_y) begin
                		next_debug = 1'b1;
            		end
				end
                
                if(rdempty) begin
                    if(ready==1'b0) begin
                        next_state = S_IDLE;
                    end
                end
                else begin
                    next_rdreq = 1'b1;
                end

                if
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
            count       <= 3'd0;
            max_count   <= 1'd0;
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
            count       <= next_count;
            max_count   <= next_max_count;
		end
	end
endmodule
