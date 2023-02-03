-------------------------------------------------------------------------------
-- Title      : Exercise 3
-- Project    : 
-------------------------------------------------------------------------------
-- File       : adder.vhd
-- Author     : Group: 17, Poojith Dasari, Andrew Gergis
-- Company    : TUT
-- Created    : 2023-02-02
-- Last update: 2023-02-02
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Architecture implementation of N-bit adder
-------------------------------------------------------------------------------
-- Copyright (c) 2023
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-02-02  1.0      qqpoda	Created
-------------------------------------------------------------------------------

-- TODO: Add VHDL Header here (in Emacs use: VHDL->Template->Insert Header )
--       Use your group number and name(s) of the group member(s)
--       in the 'author' field
--       Testbench has an example what a good header should look like

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity adder is 
    generic (
      operand_width_g :  integer
      );
        port ( clk : in std_logic;                                    -- defining inputs and outputs
               rst_n : in std_logic;                           
               a_in : in std_logic_vector (operand_width_g-1 downto 0);
               b_in : in std_logic_vector (operand_width_g-1 downto 0);
               sum_out : out std_logic_vector (operand_width_g downto 0));

end entity adder;


architecture rtl of adder is 
    signal sum_reg : signed(operand_width_g downto 0);              -- defining an internal signal to be used as a register 

begin
    process (clk, rst_n)
        begin 													 	  -- process sync_proc
            if rst_n = '0' then                                       -- asynchronous reset (active low)
                sum_reg  <= (others => '0');                          -- resetting signal value in the beginning 
            elsif clk'event and clk = '1' then				          -- rising clock edge
                sum_reg <= resize(signed(a_in),operand_width_g+1) + resize(signed(b_in),operand_width_g+1);             -- restoring addition value in the reregidtered siganl
            end if;
    end process;
    sum_out <= std_logic_vector(sum_reg);                             -- conversion of seg_reg to logic vector as the same type of the output port
end rtl;