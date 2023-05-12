-------------------------------------------------------------------------------
-- Title      : Exercise 12
-- Project    : 
-------------------------------------------------------------------------------
-- File       : i2c_config.vhd
-- Author     : Group: 17, Poojith Dasari, Andrew Gergis 
-- Company    : TU
-- Created    : 2023-04-20
-- Last update: 2023-05-07
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: I2C channel configuration
-------------------------------------------------------------------------------
-- Copyright (c) 2023 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-05-07  2.0      qqpoda	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_config is

  generic (
    ref_clk_freq_g : integer := 50000000;  -- frequency of clk_signal
    i2c_freq_g     : integer := 20000;  -- i2c-bus sclk_out frequency
    n_params_g     : integer := 15;     -- number of configuration parameters
    n_leds_g       : integer := 4);     -- number of leds on the board

  port (
    clk              : in    std_logic;
    rst_n            : in    std_logic;
    sdat_inout       : inout std_logic;
    sclk_out         : out   std_logic;
    param_status_out : out   std_logic_vector(n_leds_g-1 downto 0);
    finished_out     : out   std_logic);

end entity i2c_config;

architecture rtl of i2c_config is

  --Declaring the states
  type states_type is (start, data_transmit, read_acknowledge, stop);
  signal curr_state_r : states_type;
  
  -- tracking the number of bytes sent during state transition
  constant byte_max_count_c : integer := 3;
  signal byte_sent_r        : integer range byte_max_count_c-1 downto 0;

  -- target device address appended with R/W bit 0 on the right
  constant byte_size_c      : integer := 8;
  constant bit_count_max_c  : integer                                      := 8;
  signal aud_codec_addr_r         : std_logic_vector(bit_count_max_c-1 downto 0) := "0011010"&'0';

  -- register addresses and values parameters
  type addrs_value_type is array (n_params_g-1 downto 0) of std_logic_vector(bit_count_max_c-1 downto 0);
  signal addrs_arr_r : addrs_value_type := ("00011101","00100111","00100010","00101000","00101001","01101001","01101010","01000111","01101011","01101100","01001011","01001100","01101110","01101111","01010001");
  signal val_arr_r : addrs_value_type   := ("10000000","00000100","00001011","00000000","10000001","00001000","00000000","11100001","00001001","00001000","00001000","00001000","10001000","10001000","11110001");

  -- bit and register address indexing
  signal bit_ctr_r : integer range bit_count_max_c-1 downto -1;
  signal reg_ctr_r : integer range n_params_g-1 downto 0;

  -- -- Bit index update state
  -- signal bit_idx_updated_r : std_logic;

  -- Estimation of bclk counter limit
  constant sda_count_limit_c        : integer := ref_clk_freq_g / i2c_freq_g;
  constant sclk_count_limit_c       : integer := sda_count_limit_c/2;
  constant half_sclk_count_limit_c  : integer := sclk_count_limit_c/2;

  -- SCL counter register and SCL signal
  signal sclk_ctr_r : integer range sclk_count_limit_c-1 downto 0;
  signal sclk_r     : std_logic;

  -- SDA register value
  signal sdat_r : std_logic;

begin
  
  sync_ps : process(clk, rst_n) is
      
  begin
    if rst_n = '0' then
      curr_state_r      <= start;
      reg_ctr_r         <= n_params_g-1;
      bit_ctr_r         <= bit_count_max_c-1;
      byte_sent_r       <= 0;
      sclk_r            <= '1';
      sclk_ctr_r        <= 0;
      sdat_r            <= '1';

      param_status_out  <= (others => '0');
      finished_out      <= '0';

    elsif clk'event and clk = '1' then


      -- SCLK signal Intitialization
      if sclk_ctr_r /= (sclk_count_limit_c-1) then
        sclk_ctr_r <= sclk_ctr_r + 1;
      else
      sclk_ctr_r <= 0;
        sclk_r     <= not sclk_r;
      end if;


      -- State Machines

      case curr_state_r is
        

        -- SCL 1 SDA at the middle of SCL High to enter START State
        when start =>
          if (sclk_ctr_r = half_sclk_count_limit_c and sclk_r = '1') then
            sdat_r       <= '0';
            curr_state_r <= data_transmit;
            bit_ctr_r    <= bit_count_max_c-1;
          end if;


        -- Sending SDA data (8-bit) and tri-state ('Z') on 9th bit
        -- data_transmit state 
          
        when data_transmit => 
          if bit_ctr_r /= -1 then
            if (sclk_ctr_r = half_sclk_count_limit_c and sclk_r = '0') then  -- when there is still bit left
            bit_ctr_r <= bit_ctr_r - 1;
              case byte_sent_r is
                when 0 => -- target device address along with W/R bit
                  sdat_r <= aud_codec_addr_r(bit_ctr_r);
                when 1 => -- parameter register address
                  sdat_r <= addrs_arr_r(reg_ctr_r)(bit_ctr_r);
                when 2 => -- parameter register value
                  sdat_r <= val_arr_r(reg_ctr_r)(bit_ctr_r);
              end case;
            end if;
          else
            if (sclk_ctr_r = half_sclk_count_limit_c and sclk_r = '0') then  -- switch sdat_r to high impedance 
              sdat_r       <= 'Z';
              curr_state_r <= read_acknowledge;
              bit_ctr_r    <= bit_count_max_c-1;
            end if;
          end if;
          
        -- Read acknowledge State
        -- ACK can be recognized from SDA within the High edge of SCL
        when read_acknowledge =>
          -- acknowledge received and last for the entire High edge
          if (sclk_r = '1' and sclk_ctr_r = half_sclk_count_limit_c) then
            if sdat_inout = '1' then    -- NACK: rewrite from 1st byte
              byte_sent_r  <= 0;
              curr_state_r <= start;
              bit_ctr_r    <= bit_count_max_c-1;
              sdat_r       <= '1';
            else                        -- ACK: transmission successful
              if byte_sent_r = 2 then  -- if all 3 bytes are sent, proceed to stop
                curr_state_r <= stop;
                byte_sent_r  <= 0;
              else  -- otherwise continue writing the next byte
                byte_sent_r  <= byte_sent_r + 1;
                curr_state_r <= data_transmit;
              end if;
            end if;
          end if;


				-- signal STOP State
        when stop =>
          if (sclk_ctr_r = half_sclk_count_limit_c and sclk_r = '0') then
            sdat_r <= '0';
          end if;
          if (sclk_ctr_r = half_sclk_count_limit_c and sclk_r = '1') then
            sdat_r <= '1';
            -- set finished_out bit once all parameters have been configured
            if reg_ctr_r = 0 then
              finished_out <= '1';
            else
            reg_ctr_r    <= reg_ctr_r-1;
              finished_out <= '0';
              curr_state_r <= start;
            end if;
            -- send the amount of parameters that have been sent successfully
            param_status_out <= std_logic_vector(to_unsigned(n_params_g-reg_ctr_r, n_leds_g));
          end if;

      end case;
    end if;

  end process sync_ps;

  sdat_inout <= sdat_r;
  sclk_out   <= sclk_r;


end rtl;
