	nios2_subsystem u0 (
		.clk_clk                                      (<connected-to-clk_clk>),                                      //                                   clk.clk
		.pio_data_back_external_connection_export     (<connected-to-pio_data_back_external_connection_export>),     //     pio_data_back_external_connection.export
		.pio_fifo_q_external_connection_export        (<connected-to-pio_fifo_q_external_connection_export>),        //        pio_fifo_q_external_connection.export
		.pio_fifo_rdempty_external_connection_export  (<connected-to-pio_fifo_rdempty_external_connection_export>),  //  pio_fifo_rdempty_external_connection.export
		.pio_fifo_rdfull_external_connection_export   (<connected-to-pio_fifo_rdfull_external_connection_export>),   //   pio_fifo_rdfull_external_connection.export
		.pio_fifo_rdreq_external_connection_export    (<connected-to-pio_fifo_rdreq_external_connection_export>),    //    pio_fifo_rdreq_external_connection.export
		.reset_reset_n                                (<connected-to-reset_reset_n>),                                //                                 reset.reset_n
		.pio_ram_data_external_connection_export      (<connected-to-pio_ram_data_external_connection_export>),      //      pio_ram_data_external_connection.export
		.pio_ram_wraddress_external_connection_export (<connected-to-pio_ram_wraddress_external_connection_export>), // pio_ram_wraddress_external_connection.export
		.pio_ram_wren_external_connection_export      (<connected-to-pio_ram_wren_external_connection_export>)       //      pio_ram_wren_external_connection.export
	);

