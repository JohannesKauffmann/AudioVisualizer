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
    output logic gnd
);

    assign clk_out = vga_fifo_rdreq_sig;
    assign clk_out2 = vga_fifo_wrreq_sig;
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
    
    wire [31:0] vga_fifo_data_sig, vga_fifo_q_sig;
    wire vga_fifo_rdreq_sig, vga_fifo_wrreq_sig;

    vga_fifo vga_fifo_inst (
        .clock  ( CLOCK_50 ),
        .data   ( vga_fifo_data_sig ),
        .wrreq  ( vga_fifo_wrreq_sig ),
        .full   ( vga_fifo_full_sig ),
        .q      ( vga_fifo_q_sig ),
        .rdreq  ( vga_fifo_rdreq_sig ),
        .empty  ( vga_fifo_empty_sig )
    );
    
    logic [5:0] height[19:0];
    logic [3:0] counter = 4'd0;

    logic canRead = 1'b0;

    always_ff @ (posedge CLOCK_50)
    begin
        if (data_back == 1'b1)
        begin
            canRead <= 1'b1;
            f <= 1'b1;
        end
        else
            f <= 1'b1;

        if (canRead == 1'b1)
        begin
            counter <= counter + 4'd1;
            
            case (counter)
                4'd0:   begin
                            vga_fifo_rdreq_sig <= 1'd1;
                        end
                4'd1:   begin
                            height[0]   <= vga_fifo_q_sig[5:0];
                            height[1]   <= vga_fifo_q_sig[13:8];
                            height[2]   <= vga_fifo_q_sig[21:16];
                            height[3]   <= vga_fifo_q_sig[29:24];
//                            f <= 1'b1;
                        end
                4'd2:   begin
                            height[4]   <= vga_fifo_q_sig[5:0];
                            height[5]   <= vga_fifo_q_sig[13:8];
                            height[6]   <= vga_fifo_q_sig[21:16];
                            height[7]   <= vga_fifo_q_sig[29:24];
//                            f <= 1'b0;
                        end
                4'd3:   begin
                            if (height[0] == height[4])
                                f <= 1'b1;
                            else
                                f <= 1'b0;
                            height[8]   <= vga_fifo_q_sig[5:0];
                            height[9]   <= vga_fifo_q_sig[13:8];
                            height[10]  <= vga_fifo_q_sig[21:16];
                            height[11]  <= vga_fifo_q_sig[29:24];
                        end
                4'd4:   begin
                            height[12]  <= vga_fifo_q_sig[5:0];
                            height[13]  <= vga_fifo_q_sig[13:8];
                            height[14]  <= vga_fifo_q_sig[21:16];
                            height[15]  <= vga_fifo_q_sig[29:24];
                        end
                4'd5:   begin
                            height[16]  <= vga_fifo_q_sig[5:0];
                            height[17]  <= vga_fifo_q_sig[13:8];
                            height[18]  <= vga_fifo_q_sig[21:16];
                            height[19]  <= vga_fifo_q_sig[29:24];
                        end
                4'd6:   begin
                            vga_fifo_rdreq_sig <= 1'd0;
                            canRead <= 1'b0;
                            counter <= 4'd0;
                            height_in <= height;
//                            f <= 1'b0;
                        end
            endcase
        end
//        else
//        begin
//            for (int i = 0; i < 20; i = i + 1)
//            begin
//                height[i] = 8'd0;
//            end
//        end
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
        .pio_vga_fifo_data_external_connection_export  ( vga_fifo_data_sig ),
        .pio_vga_fifo_full_external_connection_export  ( vga_fifo_full_sig ),
        .pio_vga_fifo_wrreq_external_connection_export ( vga_fifo_wrreq_sig ),
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
