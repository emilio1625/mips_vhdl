library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity memory_stage is
  port (
    clock       : in  std_logic;
    ma_stall    : in  std_logic;
    stall_to_wb : in  std_logic;
    --+----------------------------------------------------------------------+
    --|opcode| funcion                                                       |
    --+----------------------------------------------------------------------+
    --|  x0  | guarda en 'mem_data' el dato en la direccion 'addr' de la ram |
    --|  x1  | guarda el contenido de 'data' en la direccion 'addr'          |
    --|  0x  | se envia a wb el resultado de la ALU                          |
    --|  1x  | se envia a wb 'mem_data'                                      |
    --+----------------------------------------------------------------------+
    ma_opcode   : in  std_logic_vector( 1 downto 0);
    ma_reg_dest : in  std_logic_vector( 4 downto 0);
    ma_addr     : in  std_logic_vector(31 downto 0);
    ma_data     : in  std_logic_vector(31 downto 0);
    reg_dest_wb : out std_logic_vector( 4 downto 0);
    data_out_wb : out std_logic_vector(31 downto 0);
    stall_wb    : out std_logic_vector(31 downto 0)
  );
end entity;

architecture arch of memory_stage is
	signal opcode   : std_logic_vector( 1 downto 0);
	signal addr     : std_logic_vector(31 downto 0);
	signal data     : std_logic_vector(31 downto 0);
	signal temp_reg : std_logic_vector(31 downto 0);
	signal reg_dest : std_logic_vector( 4 downto 0);
	signal mem_data : std_logic_vector(31 downto 0);
    signal stall_w  : std_logic;
begin
    ram: entity work.ram port map(
        clock    => clock,
        we       => opcode(0), -- '1' => store; '0' => load
        addr     => addr,
        data_in  => data,
        data_out => mem_data
    );

    data_out_wb <= addr when opcode(1) = '0' else mem_data;
	 reg_dest_wb <= reg_dest;
    stall_wb    <= stall_w;

    sync : process(clock) begin
        if rising_edge(clock) then
            if ma_stall = '0' then
                opcode   <= ma_opcode;
                reg_dest <= ma_reg_dest;
                data     <= ma_data;
                addr     <= ma_addr;
            end if;
            stall_w      <= stall_to_wb;
        end if;
    end process;

end architecture;
