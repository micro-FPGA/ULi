----------------------------------------------------------------------------------
-- Company: 
-- Engineer: Antti Lukats
-- 
-- Create Date: 07.05.2026 11:39:27
-- Design Name: 
-- Module Name: ULi_slave - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ULi_slave is
    Port ( data_in : in STD_LOGIC;
           data_out : out STD_LOGIC;
           clk_in : in STD_LOGIC;
           clkdiv8_in : in STD_LOGIC;
           clk_out : out STD_LOGIC;
           locked : in STD_LOGIC; 
           resetn : in STD_LOGIC; -- for simulator to be happy
           ULi_o : out STD_LOGIC;
           ULi_t : out STD_LOGIC;
           ULi_i : in STD_LOGIC
           );
end ULi_slave;

architecture Behavioral of ULi_slave is

signal count_reg : unsigned(2 downto 0);
signal toggle: std_logic;
signal clk_en: std_logic;
signal clk_prev: std_logic;

begin

clk_out <= toggle; -- 50:50 ratio

process(ULi_i, resetn)
    begin
        if resetn='0' then
            toggle <= '0';
        elsif rising_edge(ULi_i) then
            if (locked = '0') then
                toggle <= not toggle;
            else 
                if clk_en = '1' then
                    toggle <= not toggle;
                end if;
            end if;
        end if;
    end process;

process(clk_in, resetn)
    begin
        if resetn='0' then
            count_reg <= (others => '0');
            clk_en <= '0';
        elsif falling_edge(clk_in) then
            clk_prev <= clkdiv8_in; -- Save divided clock
            if (clk_prev = '0') and (clkdiv8_in = '1') then
                count_reg <= (others => '0');
            else
                count_reg <= count_reg + 1;
            end if;
            
            if count_reg = 6 then
                clk_en <= '1';
            end if;
            if count_reg = 2 then
                clk_en <= '0';
            end if;
            --
            if (count_reg = 1) and (data_in = '0') then
                
            end if;
            --
            if count_reg = 0 then
                data_out <= ULi_i;
            end if;
        end if;
    end process;

process(clk_in,locked)
    begin
        if locked = '0' then
            ULi_t <= '0';
            ULi_o <= '0';
        else 
            if rising_edge(clk_in) then
                ULi_t <= not clk_en;
                if (count_reg = 4) and (data_in = '1') then
                    ULi_o <= '1';
                end if;
                if count_reg = 5 then
                    ULi_o <= '0';
                end if;
                
            end if;
        end if;
    end process;



end Behavioral;
