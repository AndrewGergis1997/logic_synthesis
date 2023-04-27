-------------------------------------------------------------------------------
-- Title      : Exercise 12
-- Project    : 
-------------------------------------------------------------------------------
-- File       : i2c_config.vhd
-- Author     : Group: 17, Poojith Dasari, Andrew Gergis 
-- Company    : TU
-- Created    : 2023-04-20
-- Last update: 2023-04-27
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: I2C channel configuration
-------------------------------------------------------------------------------
-- Copyright (c) 2023 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-04-20  1.0      qqpoda	Created
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2c_config is
    generic(
        ref_clk_freq_g  : integer := 50000000;
        i2c_freq_g      : integer := 2000;
        n_params_g      : integer := 15;
        n_leds_g        : integer := 4
    );
    port(
        clk                 : in    std_logic;
        rst_n               : in    std_logic;
        sdat_inout          : inout std_logic;
        sclk_out            : out   std_logic;
        param_status_out    : out   std_logic_vector(n_leds_g - 1 downto 0);
        finished_out        : out   std_logic
    );
end i2c_config;

architecture rtl of i2c_config is

    constant byte_size_c : integer := 8;   -- byte size
    constant reg_size_c  : integer := 120; -- we need 120 bits to store the register addresses

    -- defining vectors for storing addresses and values of codec and registers
    constant codec_addrs_c : std_logic_vector(byte_size_c-1 downto 0) := "00101100";
    constant reg_addrs_c   : std_logic_vector(reg_size_c-1 downto 0)  := "100010101111011001110110001100101101001000110110110101101110001001010110100101101001010000010100010001001110010010111000";
    constant reg_value_c   : std_logic_vector(reg_size_c-1 downto 0)  := "100011110001000100010001000100000001000000010000100100001000011100000000000100001000000100000000110100000010000000000001";

    -- define the counter limits
    constant sda_count_limit_c          : integer := ref_clk_freq_g / i2c_freq_g ;
    constant sclk_count_limit_c         : integer := sda_count_limit_c/2 ;
    constant break_count_limit_c        : integer := sda_count_limit_c*2 ;
    constant half_sclk_count_limit_c    : integer := sclk_count_limit_c/2 ;

    -- define counters
    signal ctr_r            : integer;
    signal reg_ctr_r        : integer;
    signal sda_ctr_r        : integer;
    signal sclk_ctr_r       : integer;
    signal ack_ctr_r        : integer;

    signal z_state_r    : std_logic;
    signal sclk_r       : std_logic;
    signal ack_r        : std_logic;
    signal nack_r       : std_logic;

    signal value_select_r : integer; 
    signal all_sent_r       : std_logic;
    signal break_r          : std_logic;
    signal break_ctr_r  : integer;
    signal break_done_r     : std_logic;

    signal param_status_r   : unsigned(n_leds_g-1 downto 0);

begin

    data_process : process(clk, rst_n)
    begin
        if(rst_n = '0') then
            -- reset states for signals
            ctr_r            <= 0 ;
            reg_ctr_r        <= 0 ;
            sda_ctr_r        <= half_sclk_count_limit_c;
            sclk_ctr_r       <= 1 ;
            ack_ctr_r        <= 1 ;
            
            z_state_r   <= '0';
            sclk_r      <= '1';
            ack_r       <= '0';
            nack_r      <= '0';

            value_select_r  <=  0;
            all_sent_r      <= '0';
            break_r         <= '1';
            break_ctr_r     <= sda_count_limit_c;
            break_done_r    <= '0';

            param_status_r  <= (others => '0');

        elsif clk'event and clk = '1' then
            -- if all the data is sent, set finished_out to 1
            if all_sent_r = '1' then
                finished_out    <= '1';
                sdat_inout      <= '1';
                sclk_out        <= '1';
            elsif break_r = '1' then  -- if 3 bytes are sent, take a break and stay in stop state until new start is set.
                if break_ctr_r = break_count_limit_c then
                    sdat_inout      <= '0';
                    sclk_out        <= '1';
                    sclk_r          <= '1';
                    break_r         <= '0';
                    break_ctr_r     <=  1;
                    break_done_r    <= '1';
                    sda_ctr_r        <= half_sclk_count_limit_c;
                    sclk_ctr_r       <= 1 ;
                elsif break_ctr_r = 1 then
                    break_ctr_r <=  break_ctr_r+1;
                    sdat_inout      <= '0';
                elsif break_ctr_r = half_sclk_count_limit_c then
                    break_ctr_r <=  break_ctr_r+1;
                    sdat_inout      <= '1';
                elsif break_ctr_r = sclk_count_limit_c then
                    break_ctr_r <=  break_ctr_r+1;
                    sdat_inout      <= '1';
                    sclk_out        <= '1';
                else
                    break_ctr_r <=  break_ctr_r+1;
                end if;
            
            --break state
            elsif nack_r = '1' then

                if ack_ctr_r = half_sclk_count_limit_c then
                    sclk_out        <= not sclk_r;
                    sclk_r          <= not sclk_r;
                    ack_ctr_r   <= ack_ctr_r+1;
                elsif ack_ctr_r = half_sclk_count_limit_c + sclk_count_limit_c then
                    break_r         <= '1';
                    break_ctr_r <=  1;
                    nack_r      <= '0';
                    ack_ctr_r    <= 1 ;
                else
                    ack_ctr_r <= ack_ctr_r+1;
                end if;
            
            else
                --create sclk using sclk limit
                if sclk_ctr_r = sclk_count_limit_c then
                    sclk_out        <= not sclk_r;
                    sclk_r          <= not sclk_r;
                    sclk_ctr_r  <= 1;
                    -- check for ACK
                    if not sclk_r = '1' and z_state_r = '1' then
                        ack_r   <= '1';
                    end if;
                else
                    sclk_ctr_r  <= sclk_ctr_r+1;
                end if;
                
                --check for NACK or ACK
                if ack_r = '1' then
                    if ack_ctr_r = half_sclk_count_limit_c then
                        ack_ctr_r    <= 1 ;
                        ack_r        <= '0';
                        z_state_r    <= '0';

                        if sdat_inout = '0' then
                            if value_select_r = 0 then
                                --set param status
                                param_status_r  <= param_status_r + to_unsigned(1,n_leds_g);
                            end if;

                            --check if all data is sent
                            if reg_ctr_r = reg_size_c then
                                all_sent_r  <= '1';
                            end if;
                        else
                            if value_select_r = 0 then
                                reg_ctr_r   <= reg_ctr_r - byte_size_c;
                            else
                                value_select_r  <= 0;
                            end if;
                            nack_r      <= '1';
                            ack_ctr_r   <= 1;
                        end if;
                    else
                        ack_ctr_r   <= ack_ctr_r + 1;
                    end if;
                end if;

                --configure data to sdat line
                if sda_ctr_r = sda_count_limit_c then

                    --break after 3 bytes are sent
                    if value_select_r = 0 and break_done_r = '0' then
                        break_r     <= '1';
                    --transfer first byte of data
                    elsif value_select_r = 0 then
                        if ctr_r /= byte_size_c then
                            sdat_inout  <= codec_addrs_c(ctr_r);
                            ctr_r       <= ctr_r + 1;
                        else
                            sdat_inout      <= 'Z';
                            z_state_r       <= '1';
                            value_select_r  <= value_select_r+1;
                            ctr_r           <= 0;
                        end if;
                    --transfer second byte of data
                    elsif value_select_r = 1 then
                        if ctr_r /= byte_size_c then
                            sdat_inout  <= reg_addrs_c(reg_ctr_r);
                            ctr_r       <= ctr_r + 1;
                            reg_ctr_r   <= reg_ctr_r + 1;
                        else
                            sdat_inout      <= 'Z';
                            z_state_r       <= '1';
                            value_select_r  <= value_select_r+1;
                            reg_ctr_r       <= reg_ctr_r - byte_size_c;
                            ctr_r           <= 0;
                        end if;
                    -- transfer third byte
                    else
                        if ctr_r /= byte_size_c then
                            sdat_inout  <= reg_value_c(reg_ctr_r);
                            ctr_r       <= ctr_r + 1;
                            reg_ctr_r   <= reg_ctr_r + 1;
                        else
                            sdat_inout      <= 'Z';
                            z_state_r       <= '1';
                            break_done_r    <= '0';
                            value_select_r  <= 0;
                            ctr_r           <= 0;
                        end if;
                    end if;
                sda_ctr_r   <= 1;
                else
                    sda_ctr_r   <= sda_ctr_r + 1;
                end if;
            end if;
        end if;
    end process data_process;
    param_status_out   <= std_logic_vector(param_status_r);
end rtl;


                    