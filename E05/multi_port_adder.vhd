-------------------------------------------------------------------------------
-- Title      : Exercise 5
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_multiport_adder.vhd
-- Author     : Group: 17, Poojith Dasari, Andrew Gergis
-- Company    : TUT
-- Created    : 2023-02-16
-- Last update: 2023-02-16
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: Structural implementation of a Multi-port adder
-------------------------------------------------------------------------------
-- Copyright (c) 2023
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-02-02  1.0      qqpoda	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- defined entity
entity multi_port_adder is

  generic (
    operand_width_g   : integer := 16;    -- generic parameter with integer type with default value 16
    num_of_operands_g : integer := 4);    -- generic parameter with integer type with default value 4

  port (
    clk         : in  std_logic;          -- clock signal
    rst_n       : in  std_logic;          -- active-low reset
    operands_in : in  std_logic_vector( 15 downto 0);  -- inputs sum
    sum_out     : out std_logic_vector((operand_width_g - 1) downto 0)                         -- output sum
    );
end entity multi_port_adder;


architecture structural of multi_port_adder is

  -- introduced adder components
  component adder
    generic (

      operand_width_g : integer);       -- generic name of adder component operand_width_g
    port (

      clk     : in  std_logic;          -- clock
      rst_n   : in  std_logic;          -- active-low reset
      a_in    : in  std_logic_vector((operand_width_g - 1) downto 0);  -- input of sum
      b_in    : in  std_logic_vector((operand_width_g - 1) downto 0);  -- input of sum
      sum_out : out std_logic_vector(operand_width_g  downto 0));      -- output of sum

  end component;

  type numbers is array(((num_of_operands_g/2) - 1) downto 0) of std_logic_vector(operand_width_g downto 0);

  signal subtotal : numbers;                                        -- signal of type subtotal named numbers
  signal total    : std_logic_vector((operand_width_g + 1) downto 0);  -- signal of type total of operand_width_g+2

begin  -- structural

 --first adder connected and the place the result to vector subtotal(0).
  adder_1 : adder
    generic map (
      operand_width_g => operand_width_g)
    port map (
      clk             => clk,
      rst_n           => rst_n,
      a_in            => operands_in((operand_width_g - 1) downto 0),
      b_in            => operands_in(((operand_width_g * 2) - 1) downto operand_width_g),
      sum_out         => subtotal(0));

--second adder connected and place the result to vector subtotal(1)
  adder_2 : adder
    generic map (
      operand_width_g => operand_width_g)
    port map (
      clk             => clk,
      rst_n           => rst_n,
      a_in            => operands_in(((operand_width_g * 3) - 1) downto (operand_width_g * 2)),
      b_in            => operands_in(((operand_width_g * 4) - 1) downto (operand_width_g * 3)),
      sum_out         => subtotal(1));

--previously obtained result is added and result to total vector
  adder_3 : adder
    generic map (
      operand_width_g => (operand_width_g + 1))
    port map (
      clk             => clk,
      rst_n           => rst_n,
      a_in            => subtotal(0),
      b_in            => subtotal(1),
      sum_out         => total);

  --place the value of total vector in the output sum_out except for MSB
  sum_out <= total((operand_width_g - 1) downto 0);

  -- Severity failure is interrupted when there are 4 operands
  assert (num_of_operands_g = 4) report "severity failure  -- num_of_operands_g not equal to 4" severity failure;

end structural;

     

