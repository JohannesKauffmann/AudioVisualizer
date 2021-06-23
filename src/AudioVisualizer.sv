module AudioVisualizer
(
    input   logic   x1,
                    x2,
                    x3,
                    CLOCK_50,

                    AUD_ADC_LRCK,   // Audio left/right clock
                    AUD_BCLK,       // Audio bitclock
                    AUD_ADC_DAT,    // Audio ADC data

    inout           I2C_SDAT,

    output  logic   f,
                    ADV_BLANK_N,
                    ADV_SYNC_N,
                    VGA_HS,
                    VGA_VS,
                    VGA_CLK,

                    I2C_SCLK,
                    AUD_XCK,        // Audio master clock

    output logic [7:0] VGA_R,
    output logic [7:0] VGA_G,
    output logic [7:0] VGA_B,
    
    output logic clk_out,
    output logic clk_out2,
    output logic gnd,
    
    output logic [5:0] greenLeds
);

//    assign clk_out = vga_fifo_rdreq_sig;
    assign clk_out2 = data_back;
    assign gnd = 1'b0;

    wire [31:0] data_sig, q_sig;    // Wires used to connect the FIFO input and output data
    wire data_back, wrreq_sig, rdreq_sig;

    // majority3 function
//    assign f = (x1 && x2) || (x2 && x3) || (x1 && x3);

    // PLL for the VGA clock and Audio master clock
    pll pll_inst (
        .inclk0 (CLOCK_50),
        .c0     (VGA_CLK),
        .c1     (AUD_XCK)
    );
    
    wire [5:0] height_in[19:0];

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
    
    wire [5:0] ram_data_sig, ram_q_sig, ram_rdaddress_sig, ram_wraddress_sig;

    vga_ram	vga_ram_inst (
        .clock      ( CLOCK_50 ),
        .data       ( ram_data_sig ),
        .rdaddress  ( ram_rdaddress_sig ),
        .wraddress  ( ram_wraddress_sig ),
        .wren       ( ram_wren_sig ),
        .q          ( ram_q_sig )
	);

    logic control_bit = 1'b0;
    logic [5:0] height[19:0];
    logic [4:0] counter = 5'd0;

    logic canRead = 1'b0;
    logic finished = 1'b0;
    
    logic [6:0] address_counter = 6'd0;

    always_ff @ (posedge CLOCK_50)
    begin
        control_bit <= ~canRead;

        if (data_back == 1'b1 && finished == 1'b0)
        begin
            canRead <= 1'b1;
//            f <= 1'b1;
        end
        
        if (data_back == 1'b0)
        begin
            finished <= 1'b0;
//            f <= 1'b0;
        end

        if (canRead == 1'b1)
        begin
            counter             <= counter + 5'd1;
            address_counter     <= address_counter + 6'd1;
            ram_rdaddress_sig   <= address_counter;

            case (counter)
//                5'd0:   begin
//                            
//                        end
                5'd3:   begin
                            height[counter - 3]   = ram_q_sig;
                        end
                5'd4:   height[counter - 3]   = ram_q_sig;
                5'd5:   height[counter - 3]   = ram_q_sig;
                5'd6:   height[counter - 3]   = ram_q_sig;
                5'd7:   height[counter - 3]   = ram_q_sig;
                5'd8:   height[counter - 3]   = ram_q_sig;
                5'd9:   height[counter - 3]   = ram_q_sig;
                5'd10:   height[counter - 3]   = ram_q_sig;
                5'd11:   height[counter - 3]   = ram_q_sig;
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
                            canRead <= 1'b0;
                            counter <= 5'd0;
                            finished <= 1'b1;
                            address_counter <= 1'd0;
                            height_in <= height;
                        end
            endcase
            
            greenLeds <= ram_q_sig;
        end
    end

    wire nios2_reset_n;
    assign nios2_reset_n = 1'b1;

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
        .reset_reset_n                                 ( nios2_reset_n )
    );

    audio_config audio_config_inst (
        .clk        ( CLOCK_50 ),
        .reset      ( ~nios2_reset_n ),
        .i2c_data   ( I2C_SDAT ),
        .i2c_clk    ( I2C_SCLK )
    );

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
