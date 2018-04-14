library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity mips is
    port (
        clock : in std_logic
    );
end entity;

architecture arch of mips is
-- SeÃ±ales de IF a DECODE
    signal instruction     : std_logic_vector(31 downto 0);
    signal pc              : std_logic_vector(31 downto 0);
-- SeÃ±ales de DECODE a EX
    signal de_alu_op_ex    : std_logic_vector( 3 downto 0); -- OPCODE para la Alu
    signal de_alu_srcA_ex  : std_logic_vector( 1 downto 0); -- Fuente para operando A de la ALU
    signal de_alu_srcB_ex  : std_logic_vector( 1 downto 0); -- Fuente para operando B de la ALU
    signal de_rs_data_ex   : std_logic_vector(31 downto 0); -- Valor del $rs de la instruccion
    signal de_rt_data_ex   : std_logic_vector(31 downto 0); -- Valor del $rt de la Instruccion
    signal de_reg_dest_ex  : std_logic_vector( 4 downto 0); -- Valor donde se cargarÃ¡ el dato
    signal de_shamt_ex     : std_logic_vector( 4 downto 0); -- Shift Amount
    signal de_imm_ex       : std_logic_vector(31 downto 0); -- Dato inmediato
    signal de_pc_ex        : std_logic_vector(31 downto 0); -- Direccion de la instruccion
    signal de_stall_ex     : std_logic; -- Stall para Execute
    signal de_opcode_ma    : std_logic_vector( 1 downto 0); -- Operacion para MA
    signal de_stall_to_ma  : std_logic; -- Stall para Memory Access
    signal de_we_regfl_wb  : std_logic; -- Indica si debe de escribirse o no en la etapa de WB
    signal de_stall_to_wb  : std_logic; -- Stall para Writeback
-- SeÃ±ales de EX a MEM
    signal ex_opcode_to_ma : std_logic_vector( 1 downto 0); -- Operacion a realizar sobre memoria
    signal ex_stall_to_ma  : std_logic;
    signal ex_we_regfl_2_wb: std_logic; -- Indica si hay que escibir en el register file
    signal ex_stall_to_wb  : std_logic;
    signal ex_opcode_ma    : std_logic_vector( 1 downto 0); -- Operacion a realizar sobre memoria
    signal ex_reg_dest_ma  : std_logic_vector( 4 downto 0); -- Tambien a Data Forwarding
    signal ex_alu_res_ma   : std_logic_vector(31 downto 0); -- Tambien a Data Forwarding
    signal ex_data_ma      : std_logic_vector(31 downto 0); -- Dato a guardar en memoria
    signal ex_stall_ma     : std_logic;
    signal ex_we_regfl_wb  : std_logic;
    signal ex_stall_wb     : std_logic;
-- SeÃ±ales de MEM a WB
    signal mem_reg_dest_wb : std_logic_vector( 4 downto 0);
    signal mem_data_out_wb : std_logic_vector(31 downto 0);
    signal mem_stall_wb    : std_logic_vector(31 downto 0);
-- SeÃ±ales de DECODE a IF
    signal de_pc_load_if   : std_logic; -- SeÃ±al de carga al PC
    signal de_pc_next_if   : std_logic_vector(31 downto 0); -- Direccion a cargar en el PC
    signal de_pc_stall_if  : std_logic; -- SeÃ±al de Stall para la etapa IF
-- SeÃ±ales de WB a ID
    signal data_out_id     : std_logic_vector(31 downto 0);
    signal we_regfl_id     : std_logic;
    signal reg_dest_id     : std_logic_vector(4 downto 0);
begin
    IF: entity work.instruction_fetch port map(
        clock       => clock,
        jmp         => de_pc_load_if,
        jmp_addr    => de_pc_next_if,
        instruction => instruction,
        pc_out      => pc,
        stall       => de_pc_stall_if
    );
    DE: entity work.instruction_decode port map(
        clock => clock,
        if_instr    =>
        if_pc       =>
        wb_reg_data =>
        wb_reg_dest =>
        wb_regfl_we =>
        ex_reg_dest =>
        ex_alu_res  =>
        ma_reg_dest =>
        ma_reg_data =>
    );
end architecture;
