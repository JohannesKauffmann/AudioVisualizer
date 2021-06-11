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
        logic inRange;
        inRange = isInRange(10'd2, 10'd31, 10'd471, 10'd479);
        inRange = inRange | isInRange(10'd34, 10'd63, 10'd471, 10'd479);
        inRange = inRange | isInRange(10'd2, 10'd31, 10'd461, 10'd469);
        inRange = inRange | isInRange(10'd34, 10'd63, 10'd461, 10'd469);

//        for()
//        begin
//            //
//        end

        if (inRange)
            // TODO: check here for xy cords and color
            return 24'h23F6F0;
        else
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
