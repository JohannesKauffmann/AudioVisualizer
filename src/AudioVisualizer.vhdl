-- Contains majority3 example - for now.

LIBRARY ieee;
USE ieee.std_logic_1164.all;


ENTITY AudioVisualizer IS
   PORT( x1, x2, x3  :  IN  STD_LOGIC;
         f           :  OUT STD_LOGIC);
END AudioVisualizer;


ARCHITECTURE AudioVisualizer_rtl OF AudioVisualizer IS
BEGIN
   f <= (x1 AND x2) OR (x1 AND x3) OR (x2 AND x3);
END AudioVisualizer_rtl;
