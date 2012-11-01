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
use IEEE.std_logic_1164.ALL;
use IEEE.std_logic_ARITH.ALL;
use IEEE.std_logic_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity debouncer is Port ( 
    input : in std_logic;
    rising_tick : out std_logic;
    falling_tick : out std_logic;
    state : out  std_logic;
    clk : in  std_logic);
end debouncer;

architecture Behavioral of debouncer is
type debouncer_state_type is (low, low2hi, hi, hi2low);
signal debouncer_state : debouncer_state_type; -- reg
signal debouncer_state_next : debouncer_state_type;
signal counter : std_logic_vector(18 downto 0);
signal counter_next : std_logic_vector(18 downto 0);
signal button_state : std_logic; -- reg
signal button_state_next : std_logic;
signal falling_tick_reg : std_logic;
signal falling_tick_reg_next : std_logic;
signal rising_tick_reg : std_logic;
signal rising_tick_reg_next : std_logic;
signal input_t0, input_t1 : std_logic;		-- synchronizer regs
signal input_synch : std_logic;

-- Debounce delay is 2^19 clocks (~10ms with 50MHz clock)

begin
    process(clk)
    begin
        if(clk'event and clk='1') then
            debouncer_state <= debouncer_state_next;
            button_state <= button_state_next;
            falling_tick_reg <= falling_tick_reg_next;
            rising_tick_reg <= rising_tick_reg_next;
            counter <= counter_next;
            input_t0 <= input;							-- synchronize the asynchronous input
            input_t1 <= input_t0;
        end if;
    end process;
    
    input_synch <= input_t1;
    
    process(input_synch, debouncer_state, counter, button_state)
    begin
        -- defaults 
        button_state_next <= button_state;
        debouncer_state_next <= low;
        rising_tick_reg_next <= '0';
        falling_tick_reg_next <= '0';
        
        case debouncer_state is
            when low =>
                counter_next <= std_logic_vector(to_unsigned(1,19));
                if (input_synch = '1') then
                    debouncer_state_next <= low2hi;
                else
                    debouncer_state_next <= low;
                end if;
                
            when low2hi =>
                counter_next <= counter + 1;
                if (counter = 0) then
                    if (input_synch = '1') then
                        debouncer_state_next <= hi;
                        button_state_next <= '1';
                        rising_tick_reg_next <= '1';
                    else
                        debouncer_state_next <= low;
                    end if;
                else
                    debouncer_state_next <= low2hi;
                end if;
            
            when hi =>
                counter_next <= std_logic_vector(to_unsigned(1,19));
                if (input_synch = '0') then
                    debouncer_state_next <= hi2low;
                else
                    debouncer_state_next <= hi;
                end if;
                
            when hi2low =>
                counter_next <= counter + 1;
                if (counter = 0) then
                    if (input_synch = '0') then
                        debouncer_state_next <= low;
                        button_state_next <= '0';
                        falling_tick_reg_next <= '1';
                    else
                        debouncer_state_next <= hi;
                    end if;
                else
                    debouncer_state_next <= hi2low;
                end if;
        end case;
    end process;
    
    state <= button_state;
    rising_tick <= rising_tick_reg;
    falling_tick <= falling_tick_reg;

end Behavioral;