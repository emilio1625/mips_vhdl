library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity register_file is
  port (
    clock   : in  std_logic;
    we      : in  std_logic;
    wr_reg  : in  std_logic_vector( 4 downto 0);
    wr_data : in  std_logic_vector(31 downto 0);
    rd_reg1 : in  std_logic_vector( 4 downto 0);
    rd_reg2 : in  std_logic_vector( 4 downto 0);
    rd_data1: out std_logic_vector(31 downto 0);
    rd_data2: out std_logic_vector(31 downto 0)
  );
end entity;

architecture arch of register_file is
    type reg_file_t is array(0 to 31) of std_logic_vector(31 downto 0);
    signal reg_file : reg_file_t;
    attribute ram_init_file :  string;
    attribute ram_init_file of reg_file : signal is "register_file.mif";
begin
    reg_rd : process(clock) begin
        if rising_edge(clock) then
            rd_data1 <= reg_file(conv_integer(rd_reg1));
            rd_data2 <= reg_file(conv_integer(rd_reg2));
            if we = '1' then
                reg_file(conv_integer(wr_reg)) <= wr_data;  -- Write
                if rd_reg1 = wr_reg then  -- Data Forwarding
                    rd_data1 <= wr_data;
                end if;
                if rd_reg2 = wr_reg then  -- Data Forwarding
                    rd_data2 <= wr_data;
                end if;
            end if;
            if rd_reg1 = "00000" then
                rd_data1 <= x"00000000";
            end if;
            if rd_reg2 = "00000" then
                rd_data2 <= x"00000000";
            end if;
        end if;
    end process;
end architecture;
