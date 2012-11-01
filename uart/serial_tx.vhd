-- Copyright (c) 2012, Juha Turunen (turunen@iki.fi)
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

entity serial_tx is Port ( 
    clk_50 : in std_logic;
    reset : in std_logic;

    tx : out std_logic;
    tx_idle : out std_logic;
    din : in std_logic_vector(7 downto 0);
    din_strobe : in std_logic
);
end serial_tx;

architecture Behavioral of serial_tx is

signal tx_bit_counter, tx_bit_counter_next : std_logic_vector(3 downto 0);
signal tx_baud_generator_counter, tx_baud_generator_counter_next : std_logic_vector(9 downto 0);
signal tx_baud_tick, tx_counter_maxed, tx_idle_reg : std_logic;
signal tx_data_reg : std_logic_vector(7 downto 0);

-- To calculate the modulo you need the baud length (depends on the bps) and the clock period of the input clock
-- The modulo is basically the baud length measured in clock cycles
-- Example:
--  With 115200bps the baud length is 1s/115200 = ~8,681us and with 50MHz clock the clock period is 20ns. 
--  => 8681ns / 20ns = 434
constant tx_baud_rate_modulo : integer := 434;

begin
    process (clk_50, reset)
    begin
        if (reset = '1' ) then
            tx_bit_counter <= "1001";
            tx_idle_reg <= '1';
            tx_baud_generator_counter <= (others => '0');
        else
            if (clk_50'event and clk_50 = '1') then
                -- Tx stuff
                if (din_strobe = '1') then
                    tx_idle_reg <= '0';			-- signal master that tx is busy
                    tx_data_reg <= din;
                else
                    if (tx_bit_counter = "1001" and tx_baud_tick = '1') then
                        tx_idle_reg <= '1';		-- signal master that tx is idle
                    end if;
                end if;
                
                tx_bit_counter <= tx_bit_counter_next;
                tx_baud_generator_counter <= tx_baud_generator_counter_next;

            end if;
        end if;
    end process;
    
    tx_idle <= tx_idle_reg;
    tx_baud_tick <= '1' when tx_baud_generator_counter = tx_baud_rate_modulo - 1 else '0';

    -- Reset counter if modulo reached or moving to start bit state
    tx_baud_generator_counter_next <= (others => '0') when tx_baud_tick = '1' or din_strobe = '1' else	        
                                                 tx_baud_generator_counter + 1;
                    
    tx_bit_counter_next <= (others => '0') when din_strobe = '1' else 
                            tx_bit_counter + 1 when tx_baud_tick = '1' and tx_bit_counter /= 9 else
                            tx_bit_counter;

                        
    tx <= '0'	           when tx_bit_counter = 0 else     -- start bit
            tx_data_reg(0) when tx_bit_counter = 1 else
            tx_data_reg(1) when tx_bit_counter = 2 else
            tx_data_reg(2) when tx_bit_counter = 3 else
            tx_data_reg(3) when tx_bit_counter = 4 else
            tx_data_reg(4) when tx_bit_counter = 5 else
            tx_data_reg(5) when tx_bit_counter = 6 else
            tx_data_reg(6) when tx_bit_counter = 7 else
            tx_data_reg(7) when tx_bit_counter = 8 else
            '1';                                            -- stop bit
            
end Behavioral;

