-- Copyright (c) 2012, Juha Turunen
-- All rights reserved.
--
-- Redistribution and use in source and binary forms, with or without
-- modification, are permitted provided that the following conditions are met: 
--
-- 1. Redistributions of source code must retain the above copyright notice, this
--    list of conditions and the following disclaimer. 
-- 2. Redistributions in binary form must reproduce the above copyright notice,
--    this list of conditions and the following disclaimer in the documentation
--    and/or other materials provided with the distribution. 
--
-- THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
-- ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
-- WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
-- DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
-- ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
-- (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
-- LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
-- ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
-- (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
-- SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity bin_to_7seg is Port ( 
    value : in  std_logic_vector (3 downto 0);
    display : out std_logic_vector (6 downto 0)
);
end bin_to_7seg;

architecture Behavioral of bin_to_7seg is

begin
    display <= "1000000" when value = 0 else
               "1111001" when value = 1 else
               "0100100" when value = 2 else
               "0110000" when value = 3 else
               "0011001" when value = 4 else
               "0010010" when value = 5 else
               "0000010" when value = 6 else
               "1111000" when value = 7 else
               "0000000" when value = 8 else
               "0010000" when value = 9 else
               "0001000" when value = 10 else  -- A
               "0000011" when value = 11 else  -- B
               "1000110" when value = 12 else  -- C
               "0100001" when value = 13 else  -- D
               "0000110" when value = 14 else  -- E
               "0001110";  -- F

end Behavioral;

