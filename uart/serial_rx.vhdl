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

entity serial_rx is	port (
    clk_50 : in std_logic;
    rx : in std_logic;
    dout : out std_logic_vector(7 downto 0);
    dout_tick : out std_logic;
    error : out std_logic;
    reset : in std_logic
);
end serial_rx;

architecture Behavioral of serial_rx is 

signal rx_state, rx_state_next : std_logic_vector(3 downto 0);
signal rx_baud_generator_counter, rx_baud_generator_counter_next : std_logic_vector(10 downto 0);
signal rx_baud_tick, rx_double_baud_tick : std_logic;
signal rx_data_reg, rx_data_reg_next : std_logic_vector(7 downto 0);

-- To calculate the modulo you need the baud length (depends on the bps) and the clock period of the input clock
-- The modulo is basically the baud length measured in clock cycles
-- Example:
--  With 115200bps the baud length is 1s/115200 = ~8,681us and with 50MHz clock the clock period is 20ns. 
--  => 8681ns / 20ns = 434
constant rx_baud_rate_modulo : integer := 434;	--	115200bps 1 baud = ~8,680uS 
constant rx_baud_double_rate_modulo : integer := rx_baud_rate_modulo / 2;  -- modulo for a half bit

signal rx_t0, rx_t1 : std_logic;		-- synchronizer

begin
    process (clk_50, reset)
    begin
        if (reset = '1') then
            rx_state <= "0000";	-- idle state
            rx_baud_generator_counter <= (others => '0');
            rx_data_reg <= "00000000";
            rx_t0 <= '1';
            rx_t1 <= '1';
        else
            if (clk_50'event and clk_50 = '1') then
                -- Simple synchronizer for the asynchrous signal to avoid metastability
                rx_t0 <= rx;
                rx_t1 <= rx_t0;
                
                rx_state <= rx_state_next;
                rx_baud_generator_counter <= rx_baud_generator_counter_next;
                rx_data_reg <= rx_data_reg_next;
            end if;
        end if;		
    end process;

    dout <= rx_data_reg;

    rx_baud_tick <= '1' when rx_baud_generator_counter = rx_baud_rate_modulo - 1 else '0';
    rx_double_baud_tick <= '1' when rx_baud_generator_counter = rx_baud_double_rate_modulo - 1 else '0';
    
    -- bit counter next state, dout_tick and rx_data_reg_next logic
    process (rx_t1, rx_data_reg, rx_state, rx_baud_tick, rx_double_baud_tick, rx_baud_generator_counter)
    begin
        rx_state_next <= rx_state;
        rx_data_reg_next <= rx_data_reg;
        dout_tick <= '0';
        error <= '0';
        rx_baud_generator_counter_next <= rx_baud_generator_counter + 1;
        
        case rx_state is
            when "0000" =>		-- idle state
                if (rx_t1 = '0') then		-- start receiving when idle state and rx goes low 
                    rx_state_next <= "0001";							-- next state = start bit (0)
                    rx_baud_generator_counter_next <= (others => '0');
                end if;
                
            when "0001" =>		-- start bit starting
                if (rx_double_baud_tick = '1') then		-- move to next state when half a baud has expired ie. 
                    rx_state_next <= "0010";				-- we are in middle of the start bit
                    rx_baud_generator_counter_next <= (others => '0');
                end if;
                
            when "0010" =>		-- middle of start bit
                if (rx_baud_tick = '1') then
                    rx_state_next <= "0011";				-- after a full baud move to bit0 state
                    rx_baud_generator_counter_next <= (others => '0');
                    rx_data_reg_next <= rx_t1 & rx_data_reg(7 downto 1);
                end if;
                
            -- 8 in a middle of a data bit states
            when "0011"|"0100"|"0101"|"0110"|"0111"|"1000"|"1001" =>
                if (rx_baud_tick = '1') then
                    rx_state_next <= rx_state + 1;
                    rx_data_reg_next <= rx_t1 & rx_data_reg(7 downto 1);
                    rx_baud_generator_counter_next <= (others => '0');
                end if;
                
            when "1010" =>							-- must wait until stop bit, otherwise MSB '0' would be detected as start bit
                if (rx_baud_tick = '1') then
                    -- Make sure that the stop bit is 1 to distinguish real transmission
                    -- from the rx line just being pulled low constantly
                    if (rx_t1 = '1') then
                        rx_state_next <= "1011";
                    else
                        rx_state_next <= "1100";
                    end if;	
                end if;
                
            when "1011" =>
                dout_tick <= '1';
                rx_state_next <= "0000";
                
            when "1100" =>
                -- A false transmission was detected, most likely the rx being constantly low because the
                -- the sender hasn't opened port or something. Wait here until rx goes up and then enter 
                -- normal operation. 
                error <= '1';
                if (rx_t1 = '1') then
                    rx_state_next <= "0000";		-- to idle
                else
                    rx_state_next <= "1100";		-- keep waiting
                end if;
            when others =>
        end case;
                
    end process;

end Behavioral;