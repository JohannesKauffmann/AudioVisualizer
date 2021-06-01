module VGA_Controller
(
    input   logic   CLK,

    output  logic   ADV_BLANK_N,
                    ADV_SYNC_N,
                    VGA_HS,
                    VGA_VS,
                    VGA_CLK,
            
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

    vga_pll	vga_pll_inst (
        .inclk0 ( CLK ),
        .c0 ( VGA_CLK )
	);
    
    always_ff @ (posedge VGA_CLK)
    begin
        VGA_HS <= VGA_HS_in;
        VGA_VS <= VGA_VS_in;
        ADV_BLANK_N <= ADV_BLANK_N_in;
        h_counter <= h_counter_in;
        v_counter <= v_counter_in;
        
        VGA_R <= 8'hFF;
        VGA_G <= 8'h00;
        VGA_B <= 8'h00;
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
    end

endmodule