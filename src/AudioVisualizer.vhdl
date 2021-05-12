-- Contains majority3 example - for now.
-- Also contains NIOS II instantiation.

LIBRARY ieee;
USE ieee.std_logic_1164.all;


ENTITY AudioVisualizer IS
    PORT(   x1, x2, x3, CLK :  IN  STD_LOGIC;
            f               :  OUT STD_LOGIC);
END AudioVisualizer;


ARCHITECTURE AudioVisualizer_rtl OF AudioVisualizer IS

    COMPONENT nios2_subsystem is
    PORT (
        clk_clk       : in std_logic := 'X'; -- clk
        reset_reset_n : in std_logic := 'X'  -- reset_n
    );
    END COMPONENT nios2_subsystem;

    signal rst_n    : std_logic := '1';

BEGIN

    u0 : COMPONENT nios2_subsystem
    PORT MAP (
        clk_clk       => CLK,
        reset_reset_n => rst_n
    );

    f <= (x1 AND x2) OR (x1 AND x3) OR (x2 AND x3);

END AudioVisualizer_rtl;
