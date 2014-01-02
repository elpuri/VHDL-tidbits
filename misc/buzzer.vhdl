-- Copyright (c) 2014, Juha Turunen
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

entity buzzer is Port ( 
    clk_50 : in std_logic;
	 reset : in std_logic;
	 hilo : in std_logic;
	 active : in std_logic;
	 waveform : out std_logic );
end buzzer;

architecture Behavioral of buzzer is

signal waveform_reg, waveform_next : std_logic;
signal counter_reg, counter_next : std_logic_vector(15 downto 0);
signal flip_tick : std_logic;

begin

	process (clk_50, reset)
	begin
		if (reset = '1') then
			counter_reg <= (others => '0');
			waveform_reg <= '0';
		else 
			if (clk_50'event and clk_50 = '1') then 
				waveform_reg <= waveform_next;
				counter_reg <= counter_next;
			end if;
		end if;
	end process;

	flip_tick <= '1' when (counter_reg(15 downto 13) = "111" and hilo = '0') or (counter_reg(15) = '1' and hilo = '1') else '0'; 
	
	waveform_next <= (waveform_reg xor flip_tick) and active;
	counter_next <= counter_reg + 1 when flip_tick = '0' else (others => '0');
	waveform <= waveform_reg;

end Behavioral;