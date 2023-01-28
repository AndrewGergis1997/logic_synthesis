-------------------------------------------------------------------------------
-- Title      : Exercise 2
-- Project    : 
-------------------------------------------------------------------------------
-- File       : ripple_carry_adder.vhd
-- Author     : Group: 17, Poojith Dasari, Andrew Gergis
-- Company    : TUT
-- Created    : 2023-01-27
-- Last update: 2023-01-27
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Architecture implementation of 3-bit ripple carry adder
-------------------------------------------------------------------------------
-- Copyright (c) 2023
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-01-27  1.0      qqpoda	Created
-------------------------------------------------------------------------------

-- TODO: Add VHDL Header here (in Emacs use: VHDL->Template->Insert Header )
--       Use your group number and name(s) of the group member(s)
--       in the 'author' field
--       Testbench has an example what a good header should look like

library ieee;
use ieee.std_logic_1164.all;


-- TODO: Add library called ieee here
--       And use package called std_logic_1164 from the library

entity ripple_carry_adder is
-- TODO: Declare entity here
-- Name: ripple_carry_adder
-- No generics yet
-- Ports: a_in  3-bit std_logic_vector
--        b_in  3-bit std_logic_vector
--        s_out 4-bit std_logic_vector

port (
  a_in : in std_logic_vector(2 downto 0);
  b_in : in std_logic_vector(2 downto 0);
  s_out : out std_logic_vector(3 downto 0));

end ripple_carry_adder;

-------------------------------------------------------------------------------

-- Architecture called 'gate' is already defined. Just fill it.
-- Architecture defines an implementation for an entity

architecture gate of ripple_carry_adder is
  signal c : std_logic := '0';
  signal d : std_logic := '0';
  signal e : std_logic := '0';
  signal f : std_logic := '0';
  signal g : std_logic := '0';
  signal h : std_logic := '0';
  signal carry_ha : std_logic := '0';
  signal carry_fa : std_logic := '0';
  
  
  -- TODO: Add your internal signal declarations here
  
begin  -- gate

  -- TODO: Add signal assignments here
  -- x(0) <= y and z(2);
  -- Remember that VHDL signal assignments happen in parallel
  -- Don't use processes

  s_out(0) <= a_in(0) xor b_in(0);
  carry_ha <= a_in(0) and b_in(0);
  c <= a_in(1) xor b_in(1);
  d <= c and carry_ha;
  e <= a_in(1) and b_in(1);
  s_out(1) <= c xor carry_ha;
  carry_fa <= d or e;
  f <= a_in(2) xor b_in(2);
  g <= f and carry_fa;
  h <= a_in(2) and b_in(2);
  s_out(2) <= f xor carry_fa;
  s_out(3) <= g or h;
  
    
end gate;
