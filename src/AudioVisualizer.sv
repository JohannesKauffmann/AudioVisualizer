module AudioVisualizer
(
    input   logic   x1,
                    x2,
                    x3,
                    CLK,

    output  logic   f,
                    ADV_BLANK_N,
                    ADV_SYNC_N,
                    VGA_HS,
                    VGA_VS,
                    VGA_CLK,

    output logic [7:0] VGA_R,
    output logic [7:0] VGA_G,
    output logic [7:0] VGA_B
);

    // majority3 function
    assign f = (x1 && x2) || (x2 && x3) || (x1 && x3);

    // instantiate vga controller
    VGA_Controller vga_inst (
        .CLK(CLK),
        .ADV_BLANK_N(ADV_BLANK_N),
        .ADV_SYNC_N (ADV_SYNC_N),
        .VGA_HS     (VGA_HS),
        .VGA_VS     (VGA_VS),
        .VGA_CLK    (VGA_CLK),
        .VGA_R      (VGA_R),
        .VGA_G      (VGA_G),
        .VGA_B      (VGA_B)
    );
    
    
    wire nios2_reset_n;
    assign nios2_reset_n = 1'b1;

    // instantiate Nios II subsystem
    nios2_subsystem nios2_inst (
		.clk_clk       (CLK),
		.reset_reset_n (nios2_reset_n)
	);

endmodule
