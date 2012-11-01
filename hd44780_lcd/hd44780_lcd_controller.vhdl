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

entity lcd_controller is
Port ( 
    clk_50 : in std_logic;
    reset : in std_logic;
    di : in std_logic_vector(7 downto 0);
    do : out std_logic_vector(7 downto 0);
    write_strobe : in std_logic;
    read_strobe : in std_logic;
    register_select : in std_logic;
    read_ready : out std_logic;
    lcd_rw : out std_logic;
    lcd_en : out std_logic;
    lcd_rs : out std_logic;
    lcd_do : out std_logic_vector(7 downto 0);
    lcd_di : in std_logic_vector(7 downto 0)

);
end lcd_controller;

architecture Behavioral of lcd_controller is

signal data_out_reg, data_out_reg_next : std_logic_vector(7 downto 0);
signal data_in_reg, data_in_reg_next : std_logic_vector(7 downto 0);
signal state_reg, state_reg_next : std_logic_vector(4 downto 0);
signal lcd_en_reg, lcd_en_reg_next : std_logic;
signal lcd_rs_reg, lcd_rs_reg_next : std_logic;
signal lcd_rw_reg, lcd_rw_reg_next : std_logic;

begin
    process(clk_50, reset)
    begin
        if reset = '1' then
            data_in_reg <= (others => '0');
            data_out_reg <= "10101010";
            state_reg <= (others => '0');
            lcd_en_reg <= '0';
            lcd_rw_reg <= '0';
            lcd_rs_reg <= '0';
        else
            if clk_50'event and clk_50 = '1' then
                data_out_reg <= data_out_reg_next;
                data_in_reg <= data_in_reg_next;
                state_reg <= state_reg_next;
                lcd_en_reg <= lcd_en_reg_next;
                lcd_rs_reg <= lcd_rs_reg_next;
                lcd_rw_reg <= lcd_rw_reg_next;
            end if;
        end if;
    end process;

    do <= data_out_reg;
    lcd_do <= data_in_reg;
    lcd_rw <= lcd_rw_reg;
    lcd_rs <= lcd_rs_reg;
    lcd_en <= lcd_en_reg;

    process(state_reg, data_in_reg, lcd_en_reg, lcd_rw_reg, data_out_reg, lcd_rs_reg, register_select, write_strobe, di, read_strobe, lcd_di)
    begin
        state_reg_next <= state_reg;
        data_in_reg_next <= data_in_reg;
        data_out_reg_next <= data_out_reg;
        lcd_en_reg_next <= lcd_en_reg;
        lcd_rs_reg_next <= lcd_rs_reg;
        lcd_rw_reg_next <= lcd_rw_reg;
        read_ready <= '0';
        case state_reg is
            when "00000" =>
                if write_strobe = '1' then
                    lcd_rs_reg_next <= register_select;
                    data_in_reg_next <= di;
                    lcd_rw_reg_next <= '0';
                    state_reg_next <= "00001";
                elsif read_strobe = '1' then				
                    lcd_rs_reg_next <= register_select;					
                    lcd_rw_reg_next <= '1';
                    state_reg_next <= "10001";
                end if;
                
            when "00001" => 	-- Let the data inputs settle for one clock before rising lcd_en
                lcd_en_reg_next <= '1';
                state_reg_next <= state_reg + 1;
            when "10001" =>	-- Let the data inputs settle for one clock before rising lcd_en
                lcd_en_reg_next <= '1';				
                state_reg_next <= state_reg + 1;
            when "01101" =>	-- States in between 00001 and 01101 wait for 11 clock cycles 220ns = minimum hightime for lcd_en
                lcd_en_reg_next <= '0';			-- pull lcd_en back low
                state_reg_next <= "00000";	-- go back to idle state to wait for another strobe
            when "11100" =>	-- Save the data from the LCD hw databus to a register before pulling lcd_en low
                data_out_reg_next <= lcd_di;				
                state_reg_next <= state_reg + 1;
            when "11101" =>	-- States in between 10001 and 11101 wait for 11 clock cycles 220ns = minimum hightime for lcd_en
                read_ready <= '1'; 				-- strobe read_ready signal to let master know that it can read "do"
                lcd_en_reg_next <= '0';			-- pull lcd_en back low
                state_reg_next <= "00000";		-- go back to idle state to wait for another strobe
            when others =>		-- Go to state +1 by default
                state_reg_next <= state_reg + 1;
        end case;
    end process;
end Behavioral;