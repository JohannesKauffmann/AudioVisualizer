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

    assign clk_out = data_back[1];
    assign clk_out2 = AUD_ADC_LRCK;
    assign gnd = 1'b0;

    wire [31:0] data_sig, q_sig, data_back;    // Wires used to connect the FIFO input and output

    // majority3 function
    assign f = (x1 && x2) || (x2 && x3) || (x1 && x3);

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
        .ADV_BLANK_N(ADV_BLANK_N),
        .ADV_SYNC_N (ADV_SYNC_N),
        .VGA_HS     (VGA_HS),
        .VGA_VS     (VGA_VS),
        .VGA_R      (VGA_R),
        .VGA_G      (VGA_G),
        .VGA_B      (VGA_B)
    );

    fifo fifo_inst(
        .data   ( data_sig ),
        .wrclk  ( AUD_BCLK ),
        .wrreq  ( wrreq_sig ),
        .wrfull ( wrfull_sig ),

        .q          ( q_sig ),
        .rdclk      ( CLOCK_50 ),
        .rdreq      ( rdreq_sig ),
        .rdempty    ( rdempty_sig ),
        .rdfull     ( rdfull_sig )
    );

    wire nios2_reset_n;
    assign nios2_reset_n = 1'b1;

    // instantiate Nios II subsystem
    nios2_subsystem nios2_inst (
        .clk_clk                                        (CLOCK_50),
        .pio_fifo_q_external_connection_export          (q_sig),
        .pio_fifo_rdempty_external_connection_export    (rdempty_sig),
        .pio_fifo_rdfull_external_connection_export     (rdfull_sig),
        .pio_fifo_rdreq_external_connection_export      (rdreq_sig),
        .pio_data_back_external_connection_export       (data_back),
        .reset_reset_n                                  (nios2_reset_n)
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

        .wrfull_sig     (wrfull_sig),
        .wrreq_sig      (wrreq_sig),
        .data_sig       (data_sig)
    );

endmodule
