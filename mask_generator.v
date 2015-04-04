module MASK_GENERATOR(
    clk_25,
    rst_n,
    // ALT side
    threshold,
    // Sync Controller side
    read,
    sync_x,
    sync_y,
    ccd_r,
    ccd_g,
    ccd_b,
    dvi_r,
    dvi_g,
    dvi_b,
    // Mask side
    valid,
    mask,
    mask_x,
    mask_y
);

// ==== in/out declaration =================================
    input           clk_25;
    input           rst_n;
    // ALT side
    input   [31:0]  threshold;
    // Sync Controller side
    input           read;
    input   [9:0]   sync_x, sync_y;
    input   [4:0]   ccd_r, ccd_b, dvi_r, dvi_b;
    input   [5:0]   ccd_g, dvi_g;
    // Mask side
    output          valid;
    output          mask;
    output  [9:0]   mask_x, mask_y;
// ==== reg/wire declaration ===============================
    reg     [31:0]  diff_r, diff_g, diff_b, next_diff_r, next_diff_g, next_diff_b;
    reg             valid, next_valid;
    reg             done, next_done;
    reg             mask, next_mask;
    reg     [9:0]   mask_x, mask_y, next_mask_x, next_mask_y;
    reg     [19:0]  buffer, next_buffer;
// ==== combinational part =================================
    //assign diff_r = (ccd_r > dvi_r)? (({ccd_r, 1'b0} - {dvi_r, 1'b0})*({ccd_r, 1'b0} - {dvi_r, 1'b0})) : (({dvi_r, 1'b0} - {ccd_r, 1'b0})*({dvi_r, 1'b0} - {ccd_r, 1'b0})); 
    //assign diff_g = (ccd_g > dvi_g)? ((ccd_g - dvi_g)*(ccd_g - dvi_g)) : ((dvi_g - ccd_g)*(dvi_g - ccd_g));
    //assign diff_b = (ccd_b > dvi_b)? (({ccd_b, 1'b0} - {dvi_b, 1'b0})*({ccd_b, 1'b0} - {dvi_b, 1'b0})) : (({dvi_b, 1'b0} - {ccd_b, 1'b0})*({dvi_b, 1'b0}     - {ccd_b, 1'b0}));
    
    always@(*) begin
        next_mask = mask;
        next_mask_x = mask_x;
        next_mask_y = mask_y;
        next_done = 1'b0;
        next_buffer = buffer;
        next_valid = 1'b0;
        
        if(read) begin
            next_done = 1'b1;
            next_buffer = {sync_x, sync_y};
            if(ccd_r > dvi_r)
                next_diff_r = ({ccd_r, 1'b0} - {dvi_r, 1'b0})*({ccd_r, 1'b0} - {dvi_r, 1'b0});
            else
                next_diff_r = ({dvi_r, 1'b0} - {ccd_r, 1'b0})*({dvi_r, 1'b0} - {ccd_r, 1'b0});
            if(ccd_g > dvi_g)
                next_diff_g = (ccd_g - dvi_g)*(ccd_g - dvi_g);
            else
                next_diff_g = (dvi_g - ccd_g)*(dvi_g - ccd_g);
            if(ccd_b > dvi_b)
                next_diff_b = ({ccd_b, 1'b0} - {dvi_b, 1'b0})*({ccd_b, 1'b0} - {dvi_b, 1'b0});
            else
                next_diff_b = ({dvi_b, 1'b0} - {ccd_b, 1'b0})*({dvi_b, 1'b0} - {ccd_b, 1'b0});
        end
        if(done) begin
            next_valid = 1'b1;
            next_mask_x = buffer[19:10];
            next_mask_y = buffer[9:0];
            if((diff_r + diff_g + diff_b) > threshold) begin
                next_mask = 1'b0;
            end
            else begin
                next_mask = 1'b1;
            end
        end
    end
// ==== sequential part ====================================
    always@(posedge clk_25 or negedge rst_n) begin
        if(rst_n==0) begin
            mask    <= 1'b1;
            mask_x  <= 10'd0;
            mask_y  <= 10'd0;
            done    <= 1'b0;
            buffer  <= 20'd0;
            valid   <= 1'b0;
            diff_r  <= 31'd0;
            diff_g  <= 31'd0;
            diff_b  <= 31'd0;
        end
        else begin
            mask    <= next_mask;
            mask_x  <= next_mask_x;
            mask_y  <= next_mask_y;
            done    <= next_done;
            buffer  <= next_buffer;
            valid   <= next_valid;
            diff_r  <= next_diff_r;
            diff_g  <= next_diff_g;
            diff_b  <= next_diff_b;
        end
    end
endmodule
