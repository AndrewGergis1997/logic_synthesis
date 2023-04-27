-------------------------------------------------------------------------------
-- Title      : Exercise 12
-- Project    : 
-------------------------------------------------------------------------------
-- File       : tb_i2c_config.vhd
-- Author     : Group: 17, Poojith Dasari, Andrew Gergis 
-- Company    : TU
-- Created    : 2023-04-20
-- Last update: 2023-04-27
-- Platform   : 
-- Standard   : VHDL'93/02
-------------------------------------------------------------------------------
-- Description: testbench to check the I2C channel configuration
-------------------------------------------------------------------------------
-- Copyright (c) 2023 
-------------------------------------------------------------------------------
-- Revisions  :
-- Date        Version  Author  Description
-- 2023-04-20  1.0      qqpoda	Created
-------------------------------------------------------------------------------


Library ieee;
use ieee.std_logic_1164.all;

--Empty entity
entity tb_i2c_config is 
end tb_i2c_config;

--Architecture
architecture testbench of tb_i2c_config is

    --Number of parameters to expect 
    constant n_params_c     : integer   := 15;
    constant n_leds_c       : integer   := 4;
    constant i2c_freq_c     : integer   := 20000;
    constant ref_freq_c     : integer   := 50000000;
    constant clock_period_c : time      := 20 ns;

    constant reg_size_c     :  integer  := 120;
    constant byte_size_c    :  integer  := 8;
    constant nack_freq_c    :  integer  := 5;--send NACK on 5th counter tick
    --Every transmission consists several bytes and avery byte contains given amount of bits.
    constant n_bytes_c       :  integer   := 3;
    constant bit_count_max_c :  integer   := 8;
    --Store required addresses and values to vectors
    constant codec_addr_c  : std_logic_vector (byte_size_c-1 downto 0) := "00101100";
    constant reg_addr_c     : std_logic_vector (reg_size_c-1 downto 0)  := "100010101111011001110110001100101101001000110110110101101110001001010110100101101001010000010100010001001110010010111000";
    constant reg_value_c    : std_logic_vector (reg_size_c-1 downto 0)  := "100011110001000100010001000100000001000000010000100100001000011100000000000100001000000100000000110100000010000000000001";

    --Signals Fed to the Duv 
    signal clk      : std_logic := '0'; --Remember that default values supported only in synthesis
    signal rst_n    : std_logic := '0';

    
    -- The DUV prototype 
    component i2c_config 
    generic (
        ref_clk_freq_g  : integer;
        i2c_freq_g      : integer;
        n_params_g      : integer;
        n_Leds_g        : integer);
    port (
        clk                 : in    std_logic;
        rst_n               : in    std_logic;
        sdat_inout          : inout std_logic;
        sclk_out            : out   std_logic;
        param_status_out    : out   std_logic_vector(n_leds_g-1 downto 0);
        finished_out        : out   std_logic
    );
    end component;

    --Signals coming from the DUV 
    signal sdat         : std_logic := 'Z';
    signal sclk         : std_logic;
    signal param_status : std_logic_vector (n_leds_c-1 downto 0) ;
    signal finished     : std_logic;
    --To hold the value that will be driven to sdat when sclk is high. 
    signal sdat_r : std_logic;
    -- Counters for receiving bits and bytes 
    signal bit_counter_r  : integer range 0 to bit_count_max_c-1; 
    signal byte_counter_r : integer range 0 to n_bytes_c-1;
    -- States for the FSN 
    type states is (wait_start, read_byte, send_ack, wait_stop);
    signal curr_state_r : states;
    -- Previous values of the I2C signals for edge detection 
    signal sdat_old_r: std_logic; 
    signal sclk_old_r : std_logic;
    signal reg_counter_r : integer := 0;
    signal nack_counter_r : integer := 0;

begin --testbench
    clk     <= not clk  after clock_period_c/2;
    rst_n   <= '1'      after clock_period_c*4;

    with sclk select
        sdat    <=  sdat_r when '1', 'Z'    when others;
    
    --Component instantiation
    i2c_config_1: i2c_config 
    generic map (
        ref_clk_freq_g  => ref_freq_c,
        i2c_freq_g      => i2c_freq_c,
        n_params_g      => n_params_c,
        n_leds_g        => n_leds_c)
    port map (
        clk         => clk,
        rst_n       => rst_n,
        sdat_inout  => sdat,
        sclk_out    => sclk,
        param_status_out => param_status, 
        finished_out => finished);

    fsm_proc : process (clk,rst_n)
    begin --process fsm process
        if rst_n = '0' then     --asynchronous reset (active Cow)
            curr_state_r    <= wait_start;
            sdat_old_r      <= '0';
            sclk_old_r      <= '0';
            byte_counter_r  <= 0;
            bit_counter_r   <= 0;
            sdat_r          <= 'Z';

        elsif clk'event and clk = '1' then  -- rising clock edge
        
        -- The previous values are required for the edge detection
            sclk_old_r  <= sclk;
            sdat_old_r  <= sdat;
        -- Falling edge detection for acknowledge control
        -- Must be done on the falling edge in order to be stable during the high period of selk
            if sclk = '0' and sclk_old_r = '1' then
            --If we are supposed to send ack
                if curr_state_r = send_ack then
                    if nack_counter_r = nack_freq_c then
                        sdat_r <= '1';
                        if byte_counter_r = 2 then
                            reg_counter_r <= reg_counter_r - byte_size_c;
                        end if;
                        nack_counter_r <= nack_counter_r +1;
                    else
                        --send ack (low = ack , high = nack)
                        sdat_r          <= '0';
                        nack_counter_r  <= nack_counter_r +1;
                    end if;
                else
                    sdat_r  <= 'Z';
                end if;
            end if;

           -------------------------------------------------------------------------
            -- FSM
            case curr_state_r is

            -----------------------------------------------------------------------
            -- Wait for the start condition
                when wait_start =>
                    --while cue stays high, the sdat falls
                    if sclk = '1' and sclk_old_r = '1' and
                        sdat_old_r = '1' and sdat = '0' then
                        curr_state_r <= read_byte;
                    end if;
                
                --------------------------------------------------------------------
                -- Wait for a byte to be read 
                when read_byte =>

                    --Detect a rising edge
                    if sclk = '1' and sclK_old_r = '0' then
                        if byte_counter_r= 0 then
                            assert sdat = codec_addr_c(bit_counter_r) report "Wrong codec address" severity failure;
                        elsif byte_counter_r = 1 then
                            assert sdat = reg_addr_c(reg_counter_r + bit_counter_r) report "Wrong register address." severity failure;
                        else
                            assert sdat = reg_value_c(reg_counter_r + bit_counter_r) report "Wrong data value." severity failure;
                        end if;
                          
                        if bit_counter_r /= bit_count_max_c-1 then
                            --Normallty just receive a bit 
                            bit_counter_r <= bit_counter_r + 1;
                        else
                            if byte_counter_r = 2 then
                                reg_counter_r <= reg_counter_r + byte_size_c;
                            end if;
                            --When terminal count is reached, Let's send the ack 
                            curr_state_r  <= send_ack;
                            bit_counter_r <= 0;
                        end if; --Bit counter terminal count
                    end if; --sclk rising clock edge
                    
                --------------------------------------------------------------------
                -- Send acknowledge
                when send_ack =>

                    --Detect a rising edge
                    if sclk = '1' and sclk_old_r = '0' then
                        if byte_counter_r /= n_bytes_c-1 then
                            
                            --Transmission continues
                            byte_counter_r  <= byte_counter_r + 1;
                            curr_state_r    <= read_byte;
                        else
                            
                            --transimission is about to stop
                            byte_counter_r  <= 0;
                            curr_state_r    <= wait_stop;
                        end if;
                    end if;
                        
                ---------------------------------------------------------------------
                -- Wait for the stop condition
                when wait_stop =>
                    -- stop condition detection
                    if sclk = '1' and sclk_old_r = '1' and
                    sdat_old_r = '0' and sdat = '1' then

                        curr_state_r <= wait_start;
            
                    end if;
            end case;
        end if;
    end process fsm_proc;

    -----------------------------------------------------------------------------
    -- Asserts for verification
    -----------------------------------------------------------------------------
    --SDAT should never contain X=5 
    assert sdat /= 'X' report "Three state bus in state X" severity error;
    --End of stmulation, but not during the reset
    assert finished = '0' or rst_n = '0' report "SimuLation done" severity failure;

end testbench;
                
                    


