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
use work.all;

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

    
    --Every transmission consists several bytes and avery byte contains given amount of bits.
    constant n_bytes_c       :  integer   := 3;
    constant bit_count_max_c :  integer   := 8;
    
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
    signal bit_counter_r  : integer range -1 to bit_count_max_c-1; 
    signal byte_counter_r : integer range 0 to n_bytes_c-1;
    signal param_counter_r : integer range 0 to n_params_c - 1;

    -- States for the FSN 
    type states is (wait_start, read_byte, send_ack, wait_stop);
    signal curr_state_r : states;

    -- Array for received bytes.
    type received_bytes_array is array (0 to n_params_c * n_bytes_c - 1) of std_logic_vector(bit_count_max_c - 1 downto 0);
    signal received_bytes_r : received_bytes_array;

    signal nack_sent_r : std_logic;
    signal nack_count_r : integer range 0 to 3;
    -- Previous values of the I2C signals for edge detection 
    signal sdat_old_r: std_logic; 
    signal sclk_old_r : std_logic;

    signal aud_addr_r : std_logic_vector(7 downto 0) := "0011010"&'0';
    
    type param_array_type is array (0 to n_params_c - 1) of std_logic_vector(bit_count_max_c - 1 downto 0);
    signal addr_arr_r : param_array_type := ("00011101","00100111","00100010","00101000","00101001","01101001","01101010","01000111","01101011","01101100","01001011","01001100","01101110","01101111","01010001");
  signal val_arr_r : param_array_type    := ("10000000","00000100","00001011","00000000","10000001","00001000","00000000","11100001","00001001","00001000","00001000","00001000","10001000","10001000","11110001");

begin --testbench
    clk     <= not clk  after clock_period_c/2;
    rst_n   <= '1'      after clock_period_c*4;

    -- Assign sdat_r when sclk is active, otherwise 'Z'.
    -- Note that sdat_r is usually 'Z'
    with sclk select sdat <=
        sdat_r when '1',
        'Z'    when others;

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
    begin --process fsm_proc
        if rst_n = '0' then     --asynchronous reset (active Cow)
            curr_state_r    <= wait_start;
            sdat_old_r      <= '0';
            sclk_old_r      <= '0';
            byte_counter_r  <= 0;
            bit_counter_r   <= bit_count_max_c - 1;
            param_counter_r <= 0;
            sdat_r          <= 'Z';
            nack_sent_r <= '0';

            for i in received_bytes_r'range loop
                received_bytes_r(i) <= (others => '0');
              end loop;

        elsif clk'event and clk = '1' then  -- rising clock edge
        
        -- The previous values are required for the edge detection
            sclk_old_r  <= sclk;
            sdat_old_r  <= sdat;
        -- Falling edge detection for acknowledge control
        -- Must be done on the falling edge in order to be stable during the high period of selk
            if sclk = '0' and sclk_old_r = '1' then
            --If we are supposed to send ack
                if curr_state_r = send_ack then
                    if ((param_counter_r = 9 and byte_counter_r = 2 and nack_sent_r = '0')
                            or (param_counter_r = 12 and byte_counter_r = 0 and nack_sent_r = '0')) then
                        if nack_count_r /= 3 then  -- Send NACK thrice.
                            sdat_r <= '1';
                            nack_sent_r <= '1';
                            nack_count_r <= nack_count_r + 1;
                        else
                            sdat_r <= '0';
                            nack_sent_r <= '0';
                        end if;
                    else
                        sdat_r <= '0';
                        nack_sent_r <= '0';
                    end if;
                else
                -- Otherwise, sdat is in high impedance state.
                    sdat_r <= 'Z';
                end if;
             end if;



            -- States cases
            case curr_state_r is


            -- Start State
                when wait_start =>
                    --while clk stays high, the sdat falls
                    if sclk = '1' and sclk_old_r = '1' and
                        sdat_old_r = '1' and sdat = '0' then
                        curr_state_r <= read_byte;
                    end if;
                
                -- Read Byte Stae   
                when read_byte =>

                    --Rising edge
                    if sclk = '1' and sclk_old_r = '0' then
                        received_bytes_r(param_counter_r * n_bytes_c + byte_counter_r)(bit_counter_r) <= sdat;
                        bit_counter_r                                                                 <= bit_counter_r - 1;
                        if bit_counter_r = 0 then
                          -- After capturing the last bit, bit_counter reset to msb
                          -- position and change state to send_ack.
                          bit_counter_r <= bit_count_max_c - 1;
                          curr_state_r  <= send_ack;
            
                        end if;
                      end if;  -- sclk rising clock edge
                    
                -- Send acknowledge State
                when send_ack =>

                    -- Detect a rising edge
                    if sclk = '1' and sclk_old_r = '0' then
                        -- If ACK, continue receiving bytes.
                        if (nack_sent_r = '0') then
                            if byte_counter_r /= n_bytes_c - 1 then
                                -- Transmission continues
                                byte_counter_r <= byte_counter_r + 1;
                                curr_state_r   <= read_byte;
                            else
                                -- Transmission is about to stop
                                byte_counter_r <= 0;
                                curr_state_r   <= wait_stop;
                            end if;
                        -- If NACK, cancel reading and return to wait_start.
                        else
                            byte_counter_r <= 0;
                            curr_state_r   <= wait_start;
                            nack_sent_r    <= '0';
                        end if;
                    end if;
                        
          
                --Stop State
                when wait_stop =>
                    -- stop condition detection
                    if (sclk = '1' and sclk_old_r = '1'
                        and sdat_old_r = '0' and sdat = '1') then

                        curr_state_r <= wait_start;
                        if (param_counter_r /= n_params_c-1) then
                            param_counter_r <= param_counter_r + 1;
                        end if;
                    end if;
            end case;
        end if;
    end process fsm_proc;


  -- Asserts for verification
  verify_data_proc : process(finished, received_bytes_r)
    -- Helper function to convert std_logic_vector to string.
    function slv_to_string(vec : std_logic_vector) return string is
      variable return_value : string(vec'length downto 1) := (others => NUL);
    begin
      for i in vec'length - 1 downto 0 loop
        return_value(i + 1) := std_logic'image(vec(i))(2);
      end loop;
      return return_value;

    end function;

    
    -- Helper procedure to assert that two bytes equals.
    procedure assert_byte(received_byte  : std_logic_vector(bit_count_max_c - 1 downto 0);
                          expected_value : std_logic_vector(bit_count_max_c - 1 downto 0);
                          error_msg_base : string
                          ) is
    begin

      assert received_byte = expected_value
        report error_msg_base & "Expected: " & slv_to_string(expected_value) & ", but recieved data was " & slv_to_string(received_byte)
        severity failure;

    end procedure;

  begin
    if (finished = '1') then
      for i in 0 to n_params_c - 1 loop
        -- Correct slave address and write-bit was always sent.
        assert_byte(received_bytes_r(n_bytes_c * i + 0),
                    aud_addr_r,
                    "Incorrect slave address received. "
                    );

        -- Correct parameter addresses are sent.
        assert_byte(received_bytes_r(n_bytes_c * i + 1),
                    addr_arr_r(i),
                    "Incorrect parameter address received. "
                    );

        -- Correct parameter values are sent.
        assert_byte(received_bytes_r(n_bytes_c * i + 2),
                    val_arr_r(i),
                    "Incorrect parameter value received. "
                    );
      end loop;
    end if;
  end process verify_data_proc;
  -- SDAT should never contain X:s.
  assert sdat /= 'X' report "Three state bus in state X" severity error;

  -- End of simulation, but not during the reset
  assert finished = '0' or rst_n = '0' report
    "Simulation done" severity failure;
    
end testbench;
                
                    


