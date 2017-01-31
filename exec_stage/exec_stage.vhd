library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity exec_stage is
    port (
        clock        : in  std_logic;
        stall        : in  std_logic; -- SeÃ±al de espera
        -- Entradas de la etapa Instruction Decode
        ex_alu_op    : in  std_logic_vector( 3 downto 0); -- Operacion de la ALU
        ex_alu_srcA  : in  std_logic_vector( 1 downto 0); -- Seleccion de la fuente del operando A de la ALU
        ex_alu_srcB  : in  std_logic_vector( 1 downto 0); -- Sel. de fuente del operando B
        ex_rs_data   : in  std_logic_vector(31 downto 0); -- Contenido de $rs
        ex_rt_data   : in  std_logic_vector(31 downto 0); -- Contenido de $rt
        ex_reg_dest  : in  std_logic_vector( 4 downto 0); -- Direccion de $rd
        ex_shamt     : in  std_logic_vector( 4 downto 0); -- Numero de corrimientos
        ex_imm       : in  std_logic_vector(31 downto 0); -- Inmediato extendido
        ex_pc        : in  std_logic_vector(31 downto 0); -- Direccion de la instruccion actual
        -- Entradas de la etapa ID para ser enviadas a MA
        opcode_to_ma : in  std_logic_vector( 1 downto 0); -- Operacion a realizar sobre memoria
        stall_to_ma  : in  std_logic;
        -- Entradas de la etapa ID para ser enviadas a WB
        we_regfl_2_wb: in  std_logic; -- Indica si hay que escibir en el register file
        stall_to_wb  : in  std_logic;
        -- Salida a etapa Memory Access
        opcode_ma    : out std_logic_vector( 1 downto 0); -- Operacion a realizar sobre memoria
        reg_dest_ma  : out std_logic_vector( 4 downto 0); -- Tambien a Data Forwarding
        alu_res_ma   : out std_logic_vector(31 downto 0); -- Tambien a Data Forwarding
        data_ma      : out std_logic_vector(31 downto 0); -- Dato a guardar en memoria
        stall_ma     : out std_logic;
        -- Salida a la etapa Writeback
        we_regfl_wb  : out std_logic;
        stall_wb     : out std_logic
    );
end entity;

architecture arch of exec_stage is
    signal op_A, op_B  : std_logic_vector(31 downto 0);
    signal alu_res     : std_logic_vector(31 downto 0);
    signal alu_op      : std_logic_vector( 3 downto 0);
    signal alu_srcA    : std_logic_vector( 1 downto 0);
    signal alu_srcB    : std_logic_vector( 1 downto 0);
    signal reg_A, reg_B: std_logic_vector(31 downto 0);
    signal reg_dest    : std_logic_vector( 4 downto 0);
    signal shift       : std_logic_vector(31 downto 0);
    signal pc, imm_reg : std_logic_vector(31 downto 0);
    signal opcode_m    : std_logic_vector( 1 downto 0);
    signal we_regfl    : std_logic;
    signal stall_m     : std_logic;
    signal stall_w     : std_logic;
begin
    opA : process(alu_srcA) begin
        case alu_srcA is
            when  "00"  => op_A <= reg_A;
            when  "01"  => op_A <= reg_B;
            when  "10"  => op_A <= imm_reg;
            when  "11"  => op_A <= x"00000004";
            when others => op_A <= reg_A;
        end case;
    end process;

    opB : process(alu_srcB) begin
        case alu_srcB is
            when  "00"  => op_B <= reg_B;
            when  "01"  => op_B <= imm_reg;
            when  "10"  => op_B <= shift;
            when  "11"  => op_B <= pc;
            when others => op_B <= reg_B;
        end case;
    end process;

    alu: entity work.alu port map(
        sel  => alu_op,
        op_A => op_A,
        op_B => op_B,
        res  => alu_res
    );

    -- A la etapa MA
    opcode_ma   <= opcode_m; -- Tipo de operacion (guardar o leer, byte, halfword o word)
    reg_dest_ma <= reg_dest;  -- Registro donde cargar los datos
    alu_res_ma  <= alu_res;   -- Direccion donde guardar o cargar
    data_ma     <= reg_B;     -- Dato a guardar en memoria
    we_regfl_wb <= we_regfl;
    stall_ma    <= stall_m;
    stall_wb    <= stall_w;

    sync : process(clock)
    begin
        if rising_edge(clock) then
            if stall = '0' then
                alu_op   <= ex_alu_op;
                alu_srcA <= ex_alu_srcA;
                alu_srcB <= ex_alu_srcB;
                reg_A    <= ex_rs_data;
                reg_B    <= ex_rt_data;
                reg_dest <= ex_reg_dest;
                shift    <= x"000000" & "000" & ex_shamt;
                pc       <= ex_pc;
                imm_reg  <= ex_imm;
                opcode_m <= opcode_to_ma;
                we_regfl <= we_regfl_2_wb;
            end if;
            stall_m      <= stall_to_ma;
            stall_w      <= stall_to_wb;
        end if;
    end process;

end architecture;
