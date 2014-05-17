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
use IEEE.STD_LOGIC_UNSIGNED.ALL;
USE ieee.numeric_std.ALL;

entity spi_slave is port (
	clk : in std_logic;
	reset : in std_logic;
	sclk : in std_logic;
	mosi : in std_logic;
	miso : out std_logic;
	data_in : in std_logic_vector(7 downto 0);
	data_out : out std_logic_vector(7 downto 0);
	byte_tick : out std_logic
);
end spi_slave;

architecture Behavioral of spi_slave is

signal sclk_rising_edge, sclk_falling_edge, sclk_delay : std_logic;
signal bit_counter : unsigned(2 downto 0);
signal shift_reg : std_logic_vector(7 downto 0);

begin

	sclk_rising_edge <= '1' when sclk_delay = '0' and sclk = '1' else '0';
	sclk_falling_edge <= '1' when sclk_delay = '1' and sclk = '0' else '0';
	
	process(clk, reset)
	begin
		if (reset = '1') then
		
		elsif (clk'event and clk = '1') then

			if (sclk_rising_edge = '1') then
				shift_reg <= shift_reg(6 downto 0) & mosi;			
			end if;
			
			if (sclk_falling_edge = '1') then
				bit_counter <= bit_counter + 1;
			end if;

			sclk_delay <= sclk;
		end if;
	end process;
	
	miso <= data_in(7) when bit_counter = "000" else
			  data_in(6) when bit_counter = "001" else
			  data_in(5) when bit_counter = "010" else
			  data_in(4) when bit_counter = "011" else
			  data_in(3) when bit_counter = "100" else
			  data_in(2) when bit_counter = "101" else
			  data_in(1) when bit_counter = "110" else
			  data_in(0);
	data_out <= shift_reg;
	byte_tick <= '1' when bit_counter = "111" and sclk_falling_edge = '1' else '0';
	
end Behavioral;