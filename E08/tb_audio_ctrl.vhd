-------------------------------------------------------------------------------
-- Title      : Exercise 8
-- Project    : Audio Synthesizer
-------------------------------------------------------------------------------
-- File       : tb_audio_ctrl.vhd
-- Author     : Group: 17, Poojith Dasari, Andrew Gergis
-- Company    : TU
-- Created    : 2023-03-15
-- Last update: 2023-03-15
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: functionality of a test bench to test the audio controller
-------------------------------------------------------------------------------
-- Copyright (c) 2023 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-03-15  1.0      qqpoda	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.all;

entity tb_audio_ctrl is
end tb_audio_ctrl;


architecture testbench of tb_audio_ctrl is

  --required constants and their values defined  
  constant clk_p_c       		: time 		:= 50 ns;  --clock cycle 
  constant data_width_c  		: integer  	:= 16; --data width 
  constant sample_rate_c 		: integer  	:= 48000; 	   --sampling frequency
  constant ref_clk_c     		: integer  	:= 12288000;    --reference clockfrequency(12.288 MHz)
  constant first_wave_step_c    : integer 	:= 2;  --step size for first wave
  constant second_wave_step_c   : integer 	:= 10; --step size for second wave

  constant sync_up   : integer := 6000;	 --time at which sync_clear signal is raised
  constant sync_down : integer := 10000; --time at which sync_clear signal is reset

  --signals
  signal clk, rst_n		: std_logic := '0'; --clock and reset signal
  signal sync_clear_r	: std_logic := '0';	--reset signal for wave generations
  signal aud_bit_clk_r	: std_logic := '0';	--bit-clock signal
  signal aud_lr_clk_r	: std_logic := '0';	--left-right signal
  signal aud_data_r		: std_logic := '0';	--data output

  signal left_data_in_r 	: std_logic_vector((data_width_c - 1) downto 0);  --left wave_gen data in
  signal right_data_in_r	: std_logic_vector((data_width_c - 1) downto 0);  --right wave_gen data in
  signal left_data_out_r	: std_logic_vector((data_width_c - 1) downto 0);  --left data out
  signal right_data_out_r	: std_logic_vector((data_width_c - 1) downto 0);  --right data out
  
  
--initialising component wave_generator
  component wave_gen
    generic(
	width_g, step_g : integer);	--counter width	and step size
	
    port (
	clk, rst_n	  	:   in std_logic; --clock and reset signals
	sync_clear_n_in :   in std_logic; --reset signal for wave generation
	value_out	  	:   out std_logic_vector((width_g - 1) downto 0));

  end component;
	

--audio_ctrl component
  component audio_ctrl
    generic(
    ref_clk_freq_g  : integer;		--reference clock frequency
	data_width_g	: integer;		--data width
	sample_rate_g	: integer);		--sampling frequency

    port (
	clk, rst_n	    : in std_logic;		--clock and reset signal
    left_data_in	: in std_logic_vector((data_width_g - 1) downto 0); --left data in
	right_data_in	: in std_logic_vector((data_width_g - 1) downto 0); --right data in
	aud_bclk_out	: out std_logic;	--bit-clock out
	aud_lrclk_out	: out std_logic;	--left-right clock out
	aud_data_out	: out std_logic);	--data out

  end component;

  
--audio_codec_model component
  component audio_codec_model

    generic(
	data_width_g	: integer);	--data width

    port(
	rst_n			: in std_logic;     --reset
	aud_data_in		: in std_logic;     --audio data in
	aud_bclk_in		: in std_logic;     --bit-clock in
	aud_lrclk_in	: in std_logic;		--leftright clock in

	value_left_out 	: out std_logic_vector((data_width_g - 1) downto 0); --left channel value
	value_right_out : out std_logic_vector((data_width_g - 1) downto 0)  --right channel value
	);
  end component;
  

  --begin testbench mapping the components as required
  begin

	clk_gen : process(clk)
	begin
		clk <= not clk after clk_p_c/2;
	end process clk_gen;

	rst_n <= '1' after clk_p_c * 2;
	sync_clear_r <= '1' after clk_p_c * 80000;

    left_wave : wave_gen
	generic map(
	  width_g => data_width_c,
	  step_g  => first_wave_step_c)

	port map(
	  clk				=> clk,
	  rst_n				=> rst_n,
	  sync_clear_n_in 	=> sync_clear_r,
	  value_out			=> left_data_in_r);

    right_wave : wave_gen
	generic map(
	  width_g => data_width_c,
	  step_g  => second_wave_step_c)

	port map(
	  clk				=> clk,
	  rst_n				=> rst_n,
	  sync_clear_n_in 	=> sync_clear_r,
	  value_out			=> right_data_in_r );

    audioctrl : audio_ctrl
	generic map(
	  ref_clk_freq_g	=> ref_clk_c,
	  sample_rate_g 	=> sample_rate_c,
	  data_width_g		=> data_width_c)

	port map(
	  clk			=> clk,
	  rst_n			=> rst_n,
	  left_data_in	=> left_data_in_r,
	  right_data_in	=> right_data_in_r,
	  aud_bclk_out	=> aud_bit_clk_r,
	  aud_lrclk_out => aud_lr_clk_r,
	  aud_data_out 	=> aud_data_r);

    codecmodel : audio_codec_model
	generic map(
	  data_width_g 	=> data_width_c)

	port map(
	  rst_n				=> rst_n,
	  aud_bclk_in		=> aud_bit_clk_r,
	  aud_lrclk_in		=> aud_lr_clk_r,
	  aud_data_in		=> aud_data_r,
	  value_left_out	=> left_data_out_r,
	  value_right_out	=> right_data_out_r
	);

end testbench;

