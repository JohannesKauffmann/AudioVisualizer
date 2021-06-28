module AudioVisualizer
(
    input   logic   CLOCK_50,

                    AUD_ADC_LRCK,   // Audio left/right clock
                    AUD_BCLK,       // Audio bitclock
                    AUD_ADC_DAT,    // Audio ADC data

    inout           I2C_SDAT,

    output  logic   ADV_BLANK_N,		//VGA blanking
                    ADV_SYNC_N,		//VGA sync
                    VGA_HS,			//VGA horizontal sync
                    VGA_VS,			//VGA vertical sync
                    VGA_CLK,			//VGA clock 25,175 mhZ

                    I2C_SCLK,
                    AUD_XCK,        // Audio master clock
	 //VGA data
    output logic [7:0] VGA_R,
    output logic [7:0] VGA_G,
    output logic [7:0] VGA_B
);
	 // Wires used to connect the FIFO input and output data
    wire [31:0] data_sig, q_sig;    
	 
	 //Used for FIFO module
    wire data_back, wrreq_sig, rdreq_sig;
	 //Used for RAM module
    wire [5:0] ram_data_sig, ram_q_sig, ram_rdaddress_sig, ram_wraddress_sig;
	 
	 //control bit is used in VGA_Controller for deciding which array to read and display on screen
	 logic control_bit = 1'b0;
	 
	 //array's with height of every chart-bar
	 logic [5:0] height[19:0];
	 logic [5:0] height_in[19:0];
	 
	 //counter used for RAM case
    logic [4:0] counter = 5'd0;

	 //when can_read is 1 ram has been writen and can be read without the data changing while reading.
    logic can_read = 1'b0;
    
	 //is used in combination with data_back to detect the posedge of data_back;
    logic data_back_old = 1'b0;
    
	 //counter for RAM adress
    logic [6:0] address_counter = 6'd0;
	 
	 //reset for audio_config and nios
    wire reset_n;
    assign reset_n = 1'b1;

    always_ff @ (posedge CLOCK_50)
    begin
        control_bit <= ~can_read;
        data_back_old <= data_back;
        
		  //check for posedge of data_back
        if (data_back_old == 1'b0 && data_back == 1'b1)
            can_read <= 1'b1;
        
        if (can_read == 1'b1)
        begin
            counter             <= counter + 5'd1;
            address_counter     <= address_counter + 6'd1;
            ram_rdaddress_sig   <= address_counter;

            case (counter)
					// begin case at three because it takes 3 clocksignals before ram is read;
                5'd3:   begin
                            height[counter - 3]   = ram_q_sig;
                        end
                5'd4:   height[counter - 3]   = ram_q_sig;
                5'd5:   height[counter - 3]   = ram_q_sig;
                5'd6:   height[counter - 3]   = ram_q_sig;
                5'd7:   height[counter - 3]   = ram_q_sig;
                5'd8:   height[counter - 3]   = ram_q_sig;
                5'd9:   height[counter - 3]   = ram_q_sig;
                5'd10:  height[counter - 3]   = ram_q_sig;
                5'd11:  height[counter - 3]   = ram_q_sig;
                5'd12:  height[counter - 3]   = ram_q_sig;
                5'd13:  height[counter - 3]   = ram_q_sig;
                5'd14:  height[counter - 3]   = ram_q_sig;
                5'd15:  height[counter - 3]   = ram_q_sig;
                5'd16:  height[counter - 3]   = ram_q_sig;
                5'd17:  height[counter - 3]   = ram_q_sig;
                5'd18:  height[counter - 3]   = ram_q_sig;
                5'd19:  height[counter - 3]   = ram_q_sig;
                5'd20:  height[counter - 3]   = ram_q_sig;
                5'd21:  height[counter - 3]   = ram_q_sig;
                5'd22:  height[counter - 3]   = ram_q_sig;
                5'd23:  begin
                            can_read <= 1'b0;
                            counter <= 5'd0;
                            address_counter <= 1'd0;
                            height_in <= height;
                        end
            endcase
            
        end
    end
	 
    // PLL for the VGA clock and Audio master clock
    pll pll_inst (
        .inclk0 (CLOCK_50),
        .c0     (VGA_CLK),
        .c1     (AUD_XCK)
    );

    // instantiate vga controller
    VGA_Controller vga_inst (
        .CLK        (CLOCK_50),
        .VGA_CLK    (VGA_CLK),
        .control_bit(control_bit),
        .height     (height_in),
        .ADV_BLANK_N(ADV_BLANK_N),
        .ADV_SYNC_N (ADV_SYNC_N),
        .VGA_HS     (VGA_HS),
        .VGA_VS     (VGA_VS),
        .VGA_R      (VGA_R),
        .VGA_G      (VGA_G),
        .VGA_B      (VGA_B)
    );

	 //instantiate FIFO
    fifo fifo_inst (
        .data       ( data_sig ),
        .wrclk      ( AUD_BCLK ),
        .wrreq      ( wrreq_sig ),
        .wrempty    ( wrempty_sig ),
        .wrfull     ( wrfull_sig ),

        .q          ( q_sig ),
        .rdclk      ( CLOCK_50 ),
        .rdreq      ( rdreq_sig ),
        .rdempty    ( rdempty_sig ),
        .rdfull     ( rdfull_sig )
    );

	 //instantiate VGA RAM
    vga_ram	vga_ram_inst (
        .clock      ( CLOCK_50 ),
        .data       ( ram_data_sig ),
        .rdaddress  ( ram_rdaddress_sig ),
        .wraddress  ( ram_wraddress_sig ),
        .wren       ( ram_wren_sig ),
        .q          ( ram_q_sig )
	);

    // instantiate Nios II subsystem
    nios2_subsystem nios2_inst (
        .clk_clk                                       ( CLOCK_50 ),
        .pio_data_back_external_connection_export      ( data_back ),
        .pio_fifo_q_external_connection_export         ( q_sig ),
        .pio_fifo_rdempty_external_connection_export   ( rdempty_sig ),
        .pio_fifo_rdfull_external_connection_export    ( rdfull_sig ),
        .pio_fifo_rdreq_external_connection_export     ( rdreq_sig ),
        .pio_ram_data_external_connection_export       ( ram_data_sig ),
        .pio_ram_wraddress_external_connection_export  ( ram_wraddress_sig ),
        .pio_ram_wren_external_connection_export       ( ram_wren_sig ),
        .reset_reset_n                                 ( reset_n )
    );

	 //instantiate audio config
    audio_config audio_config_inst (
        .clk        ( CLOCK_50 ),
        .reset      ( ~reset_n ),
        .i2c_data   ( I2C_SDAT ),
        .i2c_clk    ( I2C_SCLK )
    );

	 //instantiate Audio controller
    AudioController aud_ctrl_inst (
        .AUD_ADC_CLK    (AUD_ADC_LRCK),
        .AUD_BCLK       (AUD_BCLK),
        .AUD_ADC_DATA   (AUD_ADC_DAT),

        .wrempty_sig    (wrempty_sig),
        .wrfull_sig     (wrfull_sig),
        .wrreq_sig      (wrreq_sig),
        .data_sig       (data_sig)
    );

endmodule
