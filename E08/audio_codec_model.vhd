-------------------------------------------------------------------------------
-- Title      : Exercise 8
-- Project    : 
-------------------------------------------------------------------------------
-- File       : audio_codec_model.vhd
-- Author     : Group: 17, Poojith Dasari, Andrew Gergis 
-- Company    : TU
-- Created    : 2023-03-17
-- Last update: 2023-03-17
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: functionality of audio codec model
-------------------------------------------------------------------------------
-- Copyright (c) 2023 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-03-17  1.0      qqpoda	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity audio_codec_model is

  generic(
	data_width_g  : integer := 16);		--data width
	
  port(
	rst_n		    : in std_logic;		--reset
	aud_data_in	    : in std_logic;		--data in
	aud_bclk_in	    : in std_logic;		--bit clock
	aud_lrclk_in	: in std_logic;		--left-right clock
	value_left_out	: out std_logic_vector((data_width_g - 1) downto 0); --last left channel value
	value_right_out : out std_logic_vector((data_width_g - 1) downto 0)); --last right channel value

end audio_codec_model;


architecture rtl of audio_codec_model is	
	constant data_width_c : integer := data_width_g;
	type   state_type is (wait_input, read_left, read_right);
	signal present_state_r, next_state_r : state_type := wait_input; 
	signal left_data_r  : std_logic_vector((data_width_g -1) downto 0); --register for left data channel
	signal right_data_r : std_logic_vector((data_width_g -1) downto 0); --register for right data channel
	signal right_index_r : integer := 0; 
	signal left_index_r  : integer := 0;

  begin
  
 --reset-logic sequential process
  reset_logic: process(aud_bclk_in, rst_n)

  begin
	if rst_n = '0' then
	present_state_r <= wait_input;
	right_index_r <= data_width_g-1;
	left_index_r  <= data_width_g-1;
	left_data_r     <= (others => '0');
	right_data_r    <= (others => '0');
	
	
	elsif aud_bclk_in'event and aud_bclk_in = '1' then

	  if(present_state_r /= next_state_r) then
		if next_state_r = read_left then
			left_index_r  <= data_width_g - 2;
			left_data_r(data_width_c-1) <= aud_data_in;
		elsif next_state_r = read_right then
			right_index_r  <= data_width_g - 2;
			right_data_r(data_width_c-1) <= aud_data_in;
		end if;
	else

		if present_state_r = read_left then
			if left_index_r /= -1 then
				left_data_r(left_index_r) <= aud_data_in;
				left_index_r <= left_index_r-1;
			end if;
		elsif present_state_r = read_right then
			if right_index_r /= -1 then
				right_data_r(right_index_r) <= aud_data_in;
				right_index_r <= right_index_r-1;
			end if;
		end if;
	end if;

	present_state_r <= next_state_r;
	end if;

  end process reset_logic;

--Next state, output logic based on current state and lrclk
  next_state_logic : process (aud_lrclk_in, present_state_r )
  
  begin
    
	if(present_state_r = wait_input) and (aud_lrclk_in ='1') then
		next_state_r <= read_left;
	elsif(present_state_r = wait_input) and (aud_lrclk_in ='0') then
		next_state_r <= present_state_r;
		value_right_out <= (others => '0');
		value_left_out  <= (others => '0');
	elsif(present_state_r = read_left) and (aud_lrclk_in ='0') then
		next_state_r <= read_right;
		value_left_out  <= left_data_r;
	elsif(present_state_r = read_right) and (aud_lrclk_in ='1') then
		next_state_r <= read_left;
		value_right_out <= right_data_r;
	else
	next_state_r <= present_state_r;
	end if;


  end process  next_state_logic;

  

end rtl;	
	 

















