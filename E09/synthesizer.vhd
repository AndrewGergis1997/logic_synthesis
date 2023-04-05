-------------------------------------------------------------------------------
-- Title      : Exercise 9
-- Project    : 
-------------------------------------------------------------------------------
-- File       : synthesizer.vhd
-- Author     : Group: 17, Poojith Dasari, Andrew Gergis 
-- Company    : TU
-- Created    : 2023-03-27
-- Last update: 2023-03-27
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: A data synthesizer for audio codec.
-------------------------------------------------------------------------------
-- Copyright (c) 2023 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-03-27  1.0      qqpoda	Created
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.all;

entity synthesizer is 
    generic(
        clk_freq_g      : integer := 12288000;
        sample_rate_g   : integer := 48000;
        data_width_g    : integer := 16;
        n_keys_g        : integer := 4
    );
    port(
        clk             : in std_logic;
        rst_n           : in std_logic;
        keys_in         : in std_logic_vector(n_keys_g-1 downto 0);
        aud_bclk_out    : out std_logic;
        aud_lrclk_out   : out std_logic;
        aud_data_out    : out std_logic
    );
end synthesizer;

architecture rtl of synthesizer is

    -- Constants for the step values of each wave generator and the number of inputs to the multiport adder
    constant step1_c        : integer := 1; -- step values for each wave generator
    constant step2_c        : integer := 2;
    constant step3_c        : integer := 4;
    constant step4_c        : integer := 8;
    constant num_inputs_c   : integer := 4;  --number of inputs to the multiport adder

    -- Signals for the generated waves and the combined output signal
    signal wave1_r : std_logic_vector(data_width_g-1 downto 0);
    signal wave2_r : std_logic_vector(data_width_g-1 downto 0);
    signal wave3_r : std_logic_vector(data_width_g-1 downto 0);
    signal wave4_r : std_logic_vector(data_width_g-1 downto 0);
    signal value_r : std_logic_vector(4*data_width_g-1 downto 0);

    -- Signal for the output audio data
    signal data_r  : std_logic_vector(data_width_g-1 downto 0);

     --initialising component wave_generator
    component wave_gen
        generic(
            width_g, step_g : integer);	--counter width	and step size
  
        port (
            clk, rst_n	  	:   in std_logic; --clock and reset signals
            sync_clear_n_in :   in std_logic; --reset signal for wave generation
            value_out	  	:   out std_logic_vector((width_g - 1) downto 0)); -- Output generated wave
    end component;
  

    -- Component declaration for the audio controller
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
    
    -- Component declaration for the multiport adder
    component multi_port_adder
        generic (
            operand_width_g   :     integer;  -- width of each operand
            num_of_operands_g :     integer); -- number of operands
        port (
            clk               : in  std_logic;  -- clock signal
            rst_n             : in  std_logic;  
            operands_in       : in  std_logic_vector(((operand_width_g * num_of_operands_g) - 1) downto 0);  -- input operands
            sum_out           : out std_logic_vector((operand_width_g - 1) downto 0));                       -- output sum
    end component; 

begin

    wave1_gen : wave_gen
        generic map(
            width_g  => data_width_g,       -- width of output wave
            step_g   => step1_c             -- step size of output wave
        )
        port map(
            clk                => clk,         -- clock signal
            rst_n              => rst_n,       -- active-low reset signal
            sync_clear_n_in    => keys_in(0),  --control sync_clear with button corresponding to it.
            value_out          => wave1_r      --generated wave saved in register
        );

    wave2_gen : wave_gen
        generic map(
            width_g  => data_width_g,
            step_g   => step2_c
        )
        port map(
            clk                => clk,         -- clock signal
            rst_n              => rst_n,       -- active-low reset signal
            sync_clear_n_in    => keys_in(1),  --control sync_clear with button corresponding to it.
            value_out          => wave2_r      --generated wave saved in register
        );

    wave3_gen : wave_gen
        generic map(
            width_g  => data_width_g,
            step_g   => step3_c
        )
        port map(
            clk                => clk,         -- clock signal
            rst_n              => rst_n,       -- active-low reset signal
            sync_clear_n_in    => keys_in(2),  --control sync_clear with button corresponding to it.
            value_out          => wave3_r      --generated wave saved in register
        );

    wave4_gen : wave_gen
        generic map(
            width_g  => data_width_g,
            step_g   => step4_c
        )
        port map(
            clk                => clk,         -- clock signal
            rst_n              => rst_n,       -- active-low reset signal
            sync_clear_n_in    => keys_in(3),  --control sync_clear with button corresponding to it.
            value_out          => wave4_r      --generated wave saved in register
        );
    value_r  <= (wave1_r & wave2_r & wave3_r & wave4_r) ; --combine all generated waves to a single signal to pass through multiport adder.

    -- Instantiating the multi-port adder entity and mapping its generic and port variables.
    adder : multi_port_adder
        generic map(
            operand_width_g     => data_width_g,   -- width of each input operand
            num_of_operands_g   => num_inputs_c    -- total number of input operands
        )
        port map(
            clk                => clk, 
            rst_n              => rst_n,
            operands_in        => value_r,  --outputs of wave generators are considered as inputs
            sum_out            => data_r    --resulting sum is stored in data register as output
        );
    
    audioctrl : audio_ctrl
        generic map(
            ref_clk_freq_g	=> clk_freq_g,          -- reference clock frequency
            sample_rate_g 	=> sample_rate_g,       -- sampling rate of audio data
            data_width_g	=> data_width_g)        -- width of audio data
  
        port map(
            clk			    => clk,             -- clock signal
            rst_n			=> rst_n,           -- reset signal input
            left_data_in	=> data_r,          -- passing output of adder as input for both channels
            right_data_in	=> data_r,          -- passing output of adder as input for both channels
            aud_bclk_out	=> aud_bclk_out,    -- bit clock output for audio data
            aud_lrclk_out   => aud_lrclk_out,   -- left-right clock output for audio data
            aud_data_out 	=> aud_data_out     -- audio data output
        );

end rtl;