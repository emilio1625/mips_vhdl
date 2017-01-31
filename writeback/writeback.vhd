library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity writeback is
  port (
    clock      : in  std_logic;
    ma_stall   : in  std_logic;
    ma_data_in : in  std_logic_vector(31 downto 0);
    ma_reg_dest: in  std_logic_vector(4 downto 0);
    ma_we_regfl: in  std_logic;
    data_out_id: out std_logic_vector(31 downto 0);
	 we_regfl_id: out std_logic;
    reg_dest_id: out std_logic_vector(4 downto 0)
  );
end entity;

architecture arch of writeback is
    signal data    : std_logic_vector(31 downto 0);
    signal reg_dest: std_logic_vector(4 downto 0);
	 signal we      : std_logic;
begin
    data_out_id <= data;
    reg_dest_id <= reg_dest;
	 we_regfl_id <= we;

    sync : process(clock) begin
        if rising_edge(clock) and ma_stall = '0' then
            data     <= ma_data_in;
            reg_dest <= ma_reg_dest;
				we       <= ma_we_regfl;
        end if;
    end process;
end architecture;
