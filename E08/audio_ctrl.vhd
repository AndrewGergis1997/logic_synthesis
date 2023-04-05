-------------------------------------------------------------------------------
-- Title      : Exercise 7
-- Project    : 
-------------------------------------------------------------------------------
-- File       : audio_ctrl.vhd
-- Author     : Group: 17, Poojith Dasari, Andrew Gergis
-- Company    : TU
-- Created    : 2023-03-09
-- Last update: 2022-03-09
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: functionality of audio codec controller
-------------------------------------------------------------------------------
-- Copyright (c) 2023 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-03-09  1.0      qqpoda	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_ctrl is

  generic(
	ref_clk_freq_g	: integer := 12288000;	--reference clock frequency
	sample_rate_g	: integer := 48000;	--rate of sampling
	data_width_g	: integer := 16);	--width of the data

  port(
	clk  			: in std_logic; --clock 
	rst_n			: in std_logic;	--reset 
	left_data_in	: in std_logic_vector((data_width_g - 1) downto 0);  --left data in 
	right_data_in	: in std_logic_vector((data_width_g - 1) downto 0);  --right data in
	aud_bclk_out	: out std_logic;	--Bit clock
	aud_data_out	: out std_logic;	--Data output
	aud_lrclk_out	: out std_logic);	--Left-right clock out
    
end audio_ctrl;


architecture structural of audio_ctrl is

  constant bclk_limit_c 	: integer := 1;
  constant sample_limit_c 	: integer := integer((ref_clk_freq_g)/(sample_rate_g));
  constant lrclk_limit_c 	: integer := integer(sample_limit_c/2);

  signal bclk_r 			: std_logic;
  signal bclk_counter_r 	: integer;
  signal lrclk_r 			: std_logic;
  signal lrclk_counter_r 	: integer;
  signal sample_counter_r 	: integer;

  signal left_data_r 	: std_logic_vector(data_width_g-1 downto 0);
  signal right_data_r 	: std_logic_vector(data_width_g-1 downto 0);
  signal index_r 		: integer;

  begin
	data_read : process(clk, rst_n)
	begin
		if rst_n ='0' then
			aud_bclk_out  		<= '0';
			aud_lrclk_out  		<= '0';
			aud_data_out  		<= '0';
			bclk_r 				<= '0';
			bclk_counter_r  	<=  -1;
			lrclk_r  			<= '0';
			lrclk_counter_r 	<= lrclk_limit_c - 1;
			sample_counter_r 	<= sample_limit_c;
			left_data_r 		<= (others => '0');
			right_data_r 		<= (others => '0');
			index_r 			<= 0;
		
		elsif clk'event and clk = '1' then

			if sample_counter_r = sample_limit_c then
				right_data_r 	<= right_data_in;
				left_data_r 	<= left_data_in;
				sample_counter_r <= 1;
			else
				sample_counter_r <= sample_counter_r + 1;
			end if;

			if bclk_counter_r = bclk_limit_c then
				bclk_counter_r 	<= 0;
				aud_bclk_out   	<= not bclk_r;

				if (((not bclk_r) = '0')) then
					if (lrclk_r = '0') and (index_r /= -1) then

						aud_data_out 	<= right_data_r(index_r);
						index_r 		<= index_r -1;
					elsif (lrclk_r = '1') and (index_r /= -1) then

						aud_data_out 	<= left_data_r(index_r);
						index_r 		<= index_r -1;
					else
					aud_data_out <= '0';
					end if;
				end if;
				bclk_r <= not bclk_r;
			else
			    bclk_counter_r <= bclk_counter_r + 1;
			end if;

			if lrclk_counter_r = lrclk_limit_c then

				index_r  		<= data_width_g -2;
				lrclk_counter_r <= 1;
				aud_lrclk_out 	<= not lrclk_r;


				if (not lrclk_r = '0') then
					aud_data_out <= right_data_r(data_width_g -1);
				elsif (not lrclk_r = '1') then
					aud_data_out <= left_data_r(data_width_g -1);
				end if;
				lrclk_r <= not lrclk_r;
			else
				lrclk_counter_r  <= lrclk_counter_r + 1;
			end if;
		end if;
	end process;
end structural;