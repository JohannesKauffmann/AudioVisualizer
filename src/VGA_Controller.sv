module VGA_Controller
(
    input   logic   CLK,
                    VGA_CLK,

    output  logic   ADV_BLANK_N,
                    ADV_SYNC_N,
                    VGA_HS,
                    VGA_VS,
            
    output logic [7:0] VGA_R,
    output logic [7:0] VGA_G,
    output logic [7:0] VGA_B
);

    assign ADV_SYNC_N = 1'b0; // sync on green is not used.
    
    parameter [9:0] H_TOTAL = 10'd800;
    parameter [9:0] V_TOTAL = 10'd525;
	 
	 bit [19:0] [5:0] sound_height;
	 
	 assign sound_height[0] = 6'd48;
	 assign sound_height[1] = 6'd24;
	 assign sound_height[2] = 6'd23;
	 assign sound_height[3] = 6'd20;
	 assign sound_height[4] = 6'd17;
	 assign sound_height[5] = 6'd0;
	 assign sound_height[6] = 6'd40;
	 assign sound_height[7] = 6'd3;
	 assign sound_height[8] = 6'd12;
	 assign sound_height[9] = 6'd13;
	 assign sound_height[10] = 6'd48;
	 assign sound_height[11] = 6'd24;
	 assign sound_height[12] = 6'd23;
	 assign sound_height[13] = 6'd20;
	 assign sound_height[14] = 6'd17;
	 assign sound_height[15] = 6'd28;
	 assign sound_height[16] = 6'd40;
	 assign sound_height[17] = 6'd3;
	 assign sound_height[18] = 6'd12;
	 assign sound_height[19] = 6'd13;
    
    logic VGA_HS_in, VGA_VS_in, ADV_BLANK_N_in;
    logic [9:0] h_counter, h_counter_in;
    logic [9:0] v_counter, v_counter_in;

    logic [9:0] x_pos, y_pos;   // Holds the current zero-based horizontal and vertical position

    logic [23:0] color;

    always_ff @ (posedge VGA_CLK)
    begin
        VGA_HS <= VGA_HS_in;
        VGA_VS <= VGA_VS_in;
        ADV_BLANK_N <= ADV_BLANK_N_in;
        h_counter <= h_counter_in;
        v_counter <= v_counter_in;

        VGA_R <= color[23:16];
        VGA_G <= color[15:8];
        VGA_B <= color[7:0];
    end
    
    always_comb
    begin
        color <= decideColor();
    end

    always_comb
    begin
        // horizontal and vertical counter
        h_counter_in = h_counter + 10'd1;
        v_counter_in = v_counter;
        
        if(h_counter + 10'd1 == H_TOTAL)
        begin
            h_counter_in = 10'd0;
            if(v_counter + 10'd1 == V_TOTAL)
                v_counter_in = 10'd0;
            else
                v_counter_in = v_counter + 10'd1;
        end
        
        // Horizontal sync pulse is 96 pixels long at pixels 656-752
        // (Signal is registered to ensure clean output waveform)
        VGA_HS_in = 1'b1;
        if(h_counter_in >= 10'd656 && h_counter_in < 10'd752)
            VGA_HS_in = 1'b0;
            
        // Vertical sync pulse is 2 lines (800 pixels each) long at line 490-491
        //(Signal is registered to ensure clean output waveform)
        VGA_VS_in = 1'b1;
        if(v_counter_in >= 10'd490 && v_counter_in < 10'd492)
            VGA_VS_in = 1'b0;
            
        // Display pixels (inhibit blanking) between horizontal 0-639 and vertical 0-479 (640x480)
        ADV_BLANK_N_in = 1'b0;
        if(h_counter_in < 10'd640 && v_counter_in < 10'd480)
				ADV_BLANK_N_in = 1'b1;
				
        if (h_counter_in >= 10'd0 && h_counter_in < 10'd640)
            x_pos <= h_counter_in;
        else
            x_pos <= 0;

        if (v_counter_in >= 10'd0 && v_counter_in < 10'd480)
            y_pos <= v_counter_in;
        else
            y_pos <= 0;
    end

    function [23:0] decideColor();
    begin
        // Decides, based on the current position and desired canvas,
        // which color the current pixel should get.
        logic inRange = 0;
        logic [9:0] calculated_start_x  = 10'd0;
        logic [9:0] calculated_end_x    = 10'd0;
        logic [9:0] calculated_start_y  = 10'd0;
        logic [9:0] calculated_end_y    = 10'd0;

        for (int j = 0; j < 20; j = j + 1)
        begin
            begin
                for (int i = 0; i <= sound_height[19-j]; i = i + 1)
                begin
                    if (i > 0)
                    begin
                        calculated_start_x = 642 - ((j + 1) * 32);
                        calculated_end_x = 639 - (j * 32);
                        calculated_start_y = 482 - i * 10;
                        calculated_end_y = 479 - ((i - 1) * 10);

                        inRange = inRange | isInRange(calculated_start_x, calculated_end_x, calculated_start_y, calculated_end_y);
                    end
                end
            end
        end

        if (inRange)
            begin
						if (y_pos >= 0 && y_pos < 99)
							if(y_pos < 30)
								//make top 3 blocks completely red
								return 24'hFF0000;
							else
								//16711680 == 24'hFF0000 to set red to max because there is no change in the gradient
								//everything behind the plus is to calculate the gradient of green
								//117 == the color difference of the green spectrum between 24'hFF7500 and 24'hFF0000
								//y_pos - 30 is the start of the gradient. everything before y = 30 is completely red
								//69 is the range of the gradient. gradient starts at 30 and ends at 99
								//256 is used to convert the value from being in the blue range to green
								//RGB --> B = 24'h000075 * 256 = 24'h007500 = G --> RGB
								//blue isn't calculated during the calculation because it should be 00
								
								return 16711680 + (117 * (y_pos - 30) / 69 * 256);
						else
							begin
								if(y_pos >= 100 && y_pos < 129)
									//make 3 blocks completely orange
									return 24'hFF7500;
								else
									//calculate gradient for green (see explenation at red)
									return ((256 * (479 - y_pos)) / 352 * 256 * 256) + (((139 * (y_pos - 130)) / 352 + 117) * 256);
							end
				end
        else
				if(y_pos > 240)
					//make blue-black background gradient
					return ((200 * (y_pos - 240)) / 240);
				else
					//make top half of the background black
					return 24'h000000;
    end
    endfunction
	 
    function logic isInRange
    (
        // values should be > 0 (so >= 1) with x-values <= 640 and y-values <= 480
        input logic [9:0] start_x, end_x, start_y, end_y
    );
    begin
        if ( (x_pos + 1 >= start_x && x_pos + 1 <= end_x) && (y_pos + 1 >= start_y && y_pos + 1 <= end_y) )
            return 1'b1;

        return 1'b0;
    end
    endfunction

endmodule
