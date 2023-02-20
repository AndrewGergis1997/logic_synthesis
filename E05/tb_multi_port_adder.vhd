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
-- Description: Testbench implementation of Multi-port adder
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
use std.textio.all;


entity tb_multi_port_adder is -- Entity Defintion

  generic (
    operand_width_g : integer := 3
  );
end entity tb_multi_port_adder;



architecture testbench of tb_multi_port_adder is -- Architecture of test bench

  -- Defining Constants

  constant clock_period_c  : time := 10 ns;   -- Constant Clk
  constant operand_count_c : integer := 4;    -- Number of operands
  constant duv_delay_c     : integer := 2;    -- DUV Delay 

  -- creating signals

  signal clk             : std_logic := '0';        -- Low clk signal
  signal rst_n           : std_logic := '0';        -- reset
  signal operands_r      : std_logic_vector(15 downto 0);      -- Registered input of DUV
  signal sum             : std_logic_vector(operand_width_g  downto 0); -- output of the DUV
  signal output_valid_r  : std_logic_vector(duv_delay_c downto 0) := (others => '0');  -- delay compensation

  -- Defining text files

  file input_f        : text open read_mode is "input.txt";                -- reading in input.txt-file
  file ref_results_f  : text open read_mode  is "ref_results_4b.txt";
  file output_f       : text open write_mode is "output.txt";

  component multi_port_adder
  generic (
    operand_width_g   :     integer;  
    num_of_operands_g :     integer);  
  port (
    clk               : in  std_logic;  
    rst_n             : in  std_logic;  
    operands_in       : in  std_logic_vector(((operand_width_g * num_of_operands_g) - 1) downto 0);  
    sum_out           : out std_logic_vector((operand_width_g - 1) downto 0));  
end component;

begin      --Begin Test Bench
  -- Clock generator
  clk <= not clk after clock_period_c / 2;

  -- Reset generator
  rst_n <= '1' after 4 * clock_period_c;

  -- DUV instance of multiport adder and mapping the ports
  DUV : multi_port_adder
    generic map (
      operand_width_g => (operand_width_g + 1),
      num_of_operands_g => operand_count_c
    )
    port map (
      clk => clk,
      rst_n => rst_n,
      operands_in => operands_r,
      sum_out => sum
    );


  -- initiate input reading process
  input_reader : process (clk, rst_n)
    variable value_v : line;
    type integer_variable_v is array ((operand_count_c - 1) downto 0) of integer;  -- values v
    variable values_v : integer_variable_v;

  begin -- Process Begin

    if rst_n = '0' then         -- Starting with Asynchronous active low reset 


      operands_r <= (others => '0');
      output_valid_r <= (others => '0');
      
    elsif rising_edge(clk) then

      output_valid_r <= output_valid_r((DUV_delay_c - 1) downto 0) & '1';

        if not endfile(input_f) then

          -- Read four integer values from the input file
          readline(input_f, value_v);

          for i in 0 to operand_count_c - 1 loop
            read(value_v, values_v(i));
            operands_r(((operand_count_c * (i + 1)) - 1) downto (operand_count_c * i)) <= std_logic_vector(to_signed(values_v(i), 4));
          end loop;
        end if;
      end if;
    
  end process input_reader;

  checker: process(clk)

  -- Variables 
    variable line_v         : line;
    variable value_v        : integer;
    variable output_line_v  : line;
begin -- Checker
    if rising_edge(clk) then
        if output_valid_r(duv_delay_c) = '1' then

            -- EOF has not been reached
            if not endfile(ref_results_f) then

              -- Reading from file
                readline(ref_results_f, line_v);
                read(line_v, value_v);


                assert ((to_integer(signed(sum))) = value_v) report "Unexpected sum value" severity error;

                --  Writing to Output file
                write(output_line_v, to_integer(signed(sum)));
                writeline(output_f, output_line_v);
            else
                report "Simulation done" severity note;
                assert false report "Reference file EOF reached" severity failure;
            end if;
        end if;
    end if;
end process;
end testbench;