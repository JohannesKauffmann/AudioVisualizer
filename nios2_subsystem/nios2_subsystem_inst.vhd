	component nios2_subsystem is
		port (
			clk_clk                                      : in  std_logic                     := 'X';             -- clk
			pio_data_back_external_connection_export     : out std_logic;                                        -- export
			pio_fifo_q_external_connection_export        : in  std_logic_vector(31 downto 0) := (others => 'X'); -- export
			pio_fifo_rdempty_external_connection_export  : in  std_logic                     := 'X';             -- export
			pio_fifo_rdfull_external_connection_export   : in  std_logic                     := 'X';             -- export
			pio_fifo_rdreq_external_connection_export    : out std_logic;                                        -- export
			reset_reset_n                                : in  std_logic                     := 'X';             -- reset_n
			pio_ram_data_external_connection_export      : out std_logic_vector(5 downto 0);                     -- export
			pio_ram_wraddress_external_connection_export : out std_logic_vector(5 downto 0);                     -- export
			pio_ram_wren_external_connection_export      : out std_logic                                         -- export
		);
	end component nios2_subsystem;

	u0 : component nios2_subsystem
		port map (
			clk_clk                                      => CONNECTED_TO_clk_clk,                                      --                                   clk.clk
			pio_data_back_external_connection_export     => CONNECTED_TO_pio_data_back_external_connection_export,     --     pio_data_back_external_connection.export
			pio_fifo_q_external_connection_export        => CONNECTED_TO_pio_fifo_q_external_connection_export,        --        pio_fifo_q_external_connection.export
			pio_fifo_rdempty_external_connection_export  => CONNECTED_TO_pio_fifo_rdempty_external_connection_export,  --  pio_fifo_rdempty_external_connection.export
			pio_fifo_rdfull_external_connection_export   => CONNECTED_TO_pio_fifo_rdfull_external_connection_export,   --   pio_fifo_rdfull_external_connection.export
			pio_fifo_rdreq_external_connection_export    => CONNECTED_TO_pio_fifo_rdreq_external_connection_export,    --    pio_fifo_rdreq_external_connection.export
			reset_reset_n                                => CONNECTED_TO_reset_reset_n,                                --                                 reset.reset_n
			pio_ram_data_external_connection_export      => CONNECTED_TO_pio_ram_data_external_connection_export,      --      pio_ram_data_external_connection.export
			pio_ram_wraddress_external_connection_export => CONNECTED_TO_pio_ram_wraddress_external_connection_export, -- pio_ram_wraddress_external_connection.export
			pio_ram_wren_external_connection_export      => CONNECTED_TO_pio_ram_wren_external_connection_export       --      pio_ram_wren_external_connection.export
		);

