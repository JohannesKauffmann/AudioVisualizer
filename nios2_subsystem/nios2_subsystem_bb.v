
module nios2_subsystem (
	clk_clk,
	pio_data_back_external_connection_export,
	pio_fifo_q_external_connection_export,
	pio_fifo_rdempty_external_connection_export,
	pio_fifo_rdfull_external_connection_export,
	pio_fifo_rdreq_external_connection_export,
	reset_reset_n);	

	input		clk_clk;
	output	[31:0]	pio_data_back_external_connection_export;
	input	[31:0]	pio_fifo_q_external_connection_export;
	input		pio_fifo_rdempty_external_connection_export;
	input		pio_fifo_rdfull_external_connection_export;
	output		pio_fifo_rdreq_external_connection_export;
	input		reset_reset_n;
endmodule
