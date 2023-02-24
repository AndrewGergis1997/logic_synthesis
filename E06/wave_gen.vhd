-------------------------------------------------------------------------------
-- Title      : Exercise 6
-- Project    : 
-------------------------------------------------------------------------------
-- File       : wave_gen.vhd
-- Author     : Group: 17, Poojith Dasari, Andrew Gergis 
-- Company    : TUNI
-- Created    : 2023-02-22
-- Last update: 2023-02-22
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: functionality of triangular wave generator
-------------------------------------------------------------------------------
-- Copyright (c) 2023
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-02-22  1.0      qqpoda	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Declaring entity wave_gen
entity wave_gen is
  generic (
    width_g : integer;  --count of the width in bits
    step_g  : integer); --value of interval change in the wave
  port (
    clk             : in std_logic;
	  rst_n           : in std_logic;
    sync_clear_n_in : in std_logic;
    value_out       : out std_logic_vector((width_g-1) downto 0));
end wave_gen;


architecture rtl of wave_gen is
  
  constant max_c    : integer := ((((2**(width_g-1))-1)/step_g)*step_g);  --Equation from the exercise description
  constant min_c    : integer := -max_c;       --  negative of max_c is the min value
  signal direction  : std_logic := '1';        -- initialising default direction of wave as forward(1)
  signal value_r    : std_logic_vector((width_g-1) downto 0) := (others => '0');   --register to store values
  
  
begin

  wave_gen : process(clk, rst_n)

  begin

    if rst_n = '0' then

    elsif (rising_edge(clk)) then

      if (sync_clear_n_in = '1') then       --checking when sync is high then wave is generated
      
        if direction = '1' then             -- checking the direction of wave - forward(1) or backward(0)
          -- Comparing the value_r with max_c/min_c before incrementing or decrementing with step avoids overflow
          if (to_integer(signed(value_r)) = max_c) then 
            direction <= '0';        -- change the direction when value_r = max_c
          else
            value_r <= std_logic_vector(signed(value_r) + to_signed(step_g, width_g));   --incrementing with the step value
            
            end if;
        else -- if direction = 0
          if (to_integer(signed(value_r)) = min_c) then
            direction <= '1';   -- change the direction when value_r = min_c
          else
            value_r <= std_logic_vector(signed(value_r) - to_signed(step_g, width_g));   --Decrementing with the step value
            end if;
            value_out <= value_r;
        end if;
        
      else  --Reset all the signals when sync is low
       
        value_r <= (others => '0');
        direction <= '1';
        
      end if;
      value_out <= value_r;
    end if;
	
  end process;
 
end rtl;  