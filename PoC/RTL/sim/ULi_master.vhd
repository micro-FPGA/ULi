----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 07.05.2026 11:26:45
-- Design Name: 
-- Module Name: ULi_master - Behavioral
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

entity ULi_master is
    Port ( clk : in STD_LOGIC;
           locked: in STD_LOGIC;
           data_in : in STD_LOGIC;
           data_out : out STD_LOGIC;
           ULi_o : out STD_LOGIC;
           ULi_t : out STD_LOGIC;
           ULi_i : in STD_LOGIC
           );
end ULi_master;

architecture Behavioral of ULi_master is

signal count_reg : unsigned(2 downto 0);
signal ULi_sig: std_logic;
signal din: std_logic;

begin

ULi_o <= ULi_sig;

process(clk, locked)
    begin
        if locked='0' then
            count_reg <= (others => '0');
        elsif rising_edge(clk) then
            count_reg <= count_reg + 1;
            --
            if count_reg = 0 then
                ULI_sig <= '1';
                ULi_t <= '1';
            end if;
            --
            if (count_reg = 1) and (data_in = '0') then
                ULI_sig <= '0';
            end if;
            --
            if count_reg = 3 then
                ULI_sig <= '0';
            end if;
            -- drive one clock LOW
            if count_reg = 4 then
                ULi_t <= '0';                
            end if;
            -- latch data
            if count_reg = 7 then
                data_out <= din;                                
            end if;

        end if;
    end process;

-- data clocked flip flop
process(ULi_i, count_reg)
    begin
        if count_reg = 2 then
            din <= '0';
        elsif rising_edge(ULi_i) then
            din <= '1';
        end if;
    end process;



end Behavioral;
