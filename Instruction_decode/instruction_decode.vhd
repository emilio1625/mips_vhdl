-- Copyright (c) 2017 Emilio Cabrera <emilio1625@gmail.com>
-- Instruction Decode Unit

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity instruction_decode is
    port (
        clock       : in  std_logic;
        stall       : in  std_logic;
        -- Entradas etapa Instruction Fetch
        if_instr    : in  std_logic_vector(31 downto 0); -- Instruccion desde la ROM
        if_pc       : in  std_logic_vector(31 downto 0); -- Direccion de la instruccion actual
        -- Entradas etapa Writeback
        wb_reg_data : in  std_logic_vector(31 downto 0); -- Datos a escribir en el registro
        wb_reg_dest : in  std_logic_vector( 4 downto 0); -- Registro a escribir
        wb_regfl_we : in  std_logic;                     -- Señal we al register file
        -- Entradas de la etapa Execution
            -- Señales para Data Forwarding
        ex_reg_dest : in  std_logic_vector( 4 downto 0); -- Registro donde se guardara el
        ex_alu_res  : in  std_logic_vector(31 downto 0); -- Resultado de la alu
        -- Entradas de la etapa Memory Access
            -- Señales para Data Forwarding
        ma_reg_dest : in  std_logic_vector( 4 downto 0); -- Registro donde se guardara el
        ma_reg_data : in  std_logic_vector(31 downto 0); -- Dato desde memoria RAM
        -- Salidas a etapa Execution
            -- Señales de control para la etapa Execution
        alu_op_ex   : out std_logic_vector( 3 downto 0); -- OPCODE para la Alu
        alu_srcA_ex : out std_logic_vector( 1 downto 0); -- Fuente para operando A de la ALU
        alu_srcB_ex : out std_logic_vector( 1 downto 0); -- Fuente para operando B de la ALU
        rs_data_ex  : out std_logic_vector(31 downto 0); -- Valor del $rs de la instruccion
        rt_data_ex  : out std_logic_vector(31 downto 0); -- Valor del $rt de la Instruccion
        reg_dest_ex : out std_logic_vector( 4 downto 0); -- Valor donde se cargará el dato
        shamt_ex    : out std_logic_vector( 4 downto 0); -- Shift Amount
        imm_ex      : out std_logic_vector(31 downto 0); -- Dato inmediato
        pc_ex       : out std_logic_vector(31 downto 0); -- Direccion de la instruccion
        stall_ex    : out std_logic; -- Stall para Execute
            -- Señales de control para la etapa Memory Access,
            --     deben pasar primero por execution para conservar el orden
        opcode_ma   : out std_logic_vector( 1 downto 0); -- Operacion para MA
        stall_to_ma : out std_logic; -- Stall para Memory Access
            -- Señales de control para la etapa Writeback,
            --     deben pasar primero por Execution y luego por Memory Access para conservar el orden
        we_regfl_wb : out std_logic; -- Indica si debe de escribirse o no en la etapa de WB
        stall_to_wb : out std_logic; -- Stall para Writeback
        -- Salidas a la etapa Instruction Fetch
        pc_load_if  : out std_logic; -- Señal de carga al PC
        pc_next_if  : out std_logic_vector(31 downto 0); -- Direccion a cargar en el PC
        pc_stall_if : out std_logic -- Señal de Stall para la etapa IF
    );
end entity;

architecture arch of instruction_decode is
    -- Señales de la division de la instruccion
    signal opcode, funct            : std_logic_vector( 5 downto 0);
    signal shamt                    : std_logic_vector( 4 downto 0);
    signal rs_addr, rt_addr, rd_addr: std_logic_vector( 4 downto 0);
    signal target                   : std_logic_vector(25 downto 0);
    signal imm_tmp                  : std_logic_vector(15 downto 0);
    signal imm                      : std_logic_vector(31 downto 0);
    signal r1_data, r2_data, pc     : std_logic_vector(31 downto 0);
    -- $rs, $rt temporales sin resolver del Data Forwarding
    signal rs_data_tmp, rt_data_tmp : std_logic_vector(31 downto 0);
    -- Contenido de $rs, $rt definitivo que se enviara a la siguiente etapa
    signal rs_data, rt_data         : std_logic_vector(31 downto 0);
    -- Señales para los saltos
    signal equals, lesstz, eq_zero  : boolean;
    signal jmp_type                 : std_logic_vector( 2 downto 0);
begin

    reg_file: entity work.register_file port map(
        clock    => clock,
        we       => wb_regfl_we,
        wr_reg   => wb_reg_dest,
        wr_data  => wb_reg_data,
        rd_reg1  => if_instr(25 downto 21),
        rd_data1 => r1_data,
        rd_reg2  => if_instr(20 downto 16),
        rd_data2 => r2_data
    );

    -- Sign Extend
    sign_ext: entity work.sign_ext port map(
        data_in  => imm_tmp,
        data_out => imm
    );

    -- Data Forwarding
    rs_data_tmp <= ma_reg_data when rs_addr = ma_reg_dest else r1_data;
    rs_data     <= ex_alu_res  when rs_addr = ex_reg_dest else rs_data_tmp;
    rt_data_tmp <= ma_reg_data when rt_addr = ma_reg_dest else r2_data;
    rt_data     <= ex_alu_res  when rt_addr = ex_reg_dest else rt_data_tmp;

    -- Branch Logic
    equals  <= rs_data = rt_data;
    lesstz  <= signed(rs_data) < x"00000000";
    eq_zero <= rs_data = x"00000000";

    pc_update: entity work.pc_calc port map(
        clock   => clock,
        opcode  => jmp_type,
        pc_in   => pc,
        imm     => imm,
        target  => target,
        rs_data => rs_data,
        equals  => equals,
        lesstz  => lesstz,
        eq_zero => eq_zero,
        pc_out  => pc_next_if
    );

    -- Salidas
    shamt_ex   <= shamt;
    imm_ex     <= imm;
    rs_data_ex <= rs_data;
    rt_data_ex <= rt_data;
    pc_ex      <= pc;

    sync : process(clock)
    begin
        if rising_edge(clock) then
            if stall = '0' then
                pc      <= if_pc;
                -- Instruction Split
                opcode  <= if_instr(31 downto 26);
                rs_addr <= if_instr(25 downto 21);
                rt_addr <= if_instr(20 downto 16);
                rd_addr <= if_instr(15 downto 11);
                shamt   <= if_instr(10 downto  6);
                funct   <= if_instr( 5 downto  0);
                target  <= if_instr(25 downto  0);
                imm_tmp <= if_instr(15 downto  0);
            end if;
        end if;
    end process;

    --

    decode : process(opcode, funct)
    begin
        pc_stall_if <= '0';
        case opcode is
            when "000000" =>
                case funct is
                    when "100000" | "100001" => -- add(u) $rd, $rs, $rt
                        alu_op_ex   <= "1001"; -- add
                        alu_srcA_ex <= "00";   -- rs
                        alu_srcB_ex <= "00";   -- rt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "100100" => -- and $rd, $rs, $rt
                        alu_op_ex   <= "0000"; -- add
                        alu_srcA_ex <= "00";   -- rs
                        alu_srcB_ex <= "00";   -- rt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";    -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "001001" => -- jalr [$rd, ]$rs
                        jmp_type    <= "111";  -- jr
                        alu_op_ex   <= "1001"; -- add
                        alu_srcA_ex <= "11";   -- 4
                        alu_srcB_ex <= "11";   -- pc
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                        pc_stall_if <= '1';
                    when "001000" => -- jr $rs
                        jmp_type    <= "111";  -- jr
                        alu_op_ex   <= "0000"; -- and
                        alu_srcA_ex <= "00";   -- rs
                        alu_srcB_ex <= "00";   -- rt
                        reg_dest_ex <= "00000";-- zero
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '1';    -- no detengas la etapa
                        stall_to_ma <= '1';    -- no detengas la etapa
                        stall_to_wb <= '1';    -- no detengas la etapa
                        we_regfl_wb <= '0';    -- Escribe al Register File
                        pc_stall_if <= '1';
                    when "100111" => -- nor $rd, $rs, $rt
                        alu_op_ex   <= "0010"; -- nor
                        alu_srcA_ex <= "00";   -- rs
                        alu_srcB_ex <= "00";   -- rt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "100101" => -- or $rd, $rs, $rt
                        alu_op_ex   <= "0001"; -- or
                        alu_srcA_ex <= "00";   -- rs
                        alu_srcB_ex <= "00";   -- rt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "000000" => -- sll $rd, $rt, <shift_amt>
                        alu_op_ex   <= "0100"; -- sll
                        alu_srcA_ex <= "01";   -- rt
                        alu_srcB_ex <= "10";   -- shift_amt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "000100" => -- sllv $rd, $rt, $rs
                        alu_op_ex   <= "0100"; -- sll
                        alu_srcA_ex <= "00";   -- rs
                        alu_srcB_ex <= "00";   -- rt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "101010" => -- slt $rd, $rt, $rs
                        alu_op_ex   <= "0111"; -- slt
                        alu_srcA_ex <= "00";   -- rs
                        alu_srcB_ex <= "00";   -- rt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "101011" => -- sltu $rd, $rt, $rs
                        alu_op_ex   <= "1000"; -- sltu
                        alu_srcA_ex <= "00";   -- rs
                        alu_srcB_ex <= "00";   -- rt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "000011" => -- sra $rd, $rt, <shift_amt>
                        alu_op_ex   <= "0110"; -- sra
                        alu_srcA_ex <= "01";   -- rt
                        alu_srcB_ex <= "10";   -- shift_amt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "000111" => -- srav $rd, $rt, $rs
                        alu_op_ex   <= "0110"; -- srav
                        alu_srcA_ex <= "00";   -- rs
                        alu_srcB_ex <= "00";   -- rt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "000010" => -- srl $rd, $rt, <shift_amt>
                        alu_op_ex   <= "0101"; -- srl
                        alu_srcA_ex <= "01";   -- rt
                        alu_srcB_ex <= "10";   -- shift_amt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "000110" => -- srlv $rd, $rt, $rs
                        alu_op_ex   <= "0101"; -- srlv
                        alu_srcA_ex <= "00";   -- rs
                        alu_srcB_ex <= "00";   -- rt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "100010" | "100011" => -- sub(u) $rd, $rs, $rt
                        alu_op_ex   <= "1010"; -- sub
                        alu_srcA_ex <= "00";   -- rs
                        alu_srcB_ex <= "00";   -- rt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when "100110" => -- xor $rd, $rs, $rt
                        alu_op_ex   <= "0011"; -- xor
                        alu_srcA_ex <= "00";   -- rs
                        alu_srcB_ex <= "00";   -- rt
                        reg_dest_ex <= rd_addr;-- rd
                        opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                        stall_ex    <= '0';    -- no detengas la etapa
                        stall_to_ma <= '0';    -- no detengas la etapa
                        stall_to_wb <= '0';    -- no detengas la etapa
                        we_regfl_wb <= '1';    -- Escribe al Register File
                    when others =>
                end case;
            when "001000" | "001001" => -- addi(u) $rt, $rs, <immed>
                alu_op_ex   <= "1001"; -- add
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "01";   -- immed
                reg_dest_ex <= rt_addr;-- rt
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '0';    -- no detengas la etapa
                stall_to_ma <= '0';    -- no detengas la etapa
                stall_to_wb <= '0';    -- no detengas la etapa
                we_regfl_wb <= '1';    -- Escribe al Register File
            when "001100" => -- andi $rt, $rs, <immed>
                alu_op_ex   <= "0000"; -- and
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "01";   -- immed
                reg_dest_ex <= rt_addr;-- rt
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '0';    -- no detengas la etapa
                stall_to_ma <= '0';    -- no detengas la etapa
                stall_to_wb <= '0';    -- no detengas la etapa
                we_regfl_wb <= '1';    -- Escribe al Register File
            when "000100" => -- beq $rt, $rs, <offset>
                jmp_type    <= "000";  -- beq
                alu_op_ex   <= "0000"; -- and
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "00";   -- rt
                reg_dest_ex <= "00000";-- zero
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '1';    -- no detengas la etapa
                stall_to_ma <= '1';    -- no detengas la etapa
                stall_to_wb <= '1';    -- no detengas la etapa
                we_regfl_wb <= '0';    -- Escribe al Register File
                pc_stall_if <= '1';
            when "000111" => -- bgtz $rs, <offset>
                jmp_type    <= "011";  -- bgtz
                alu_op_ex   <= "0000"; -- and
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "00";   -- rt
                reg_dest_ex <= "00000";-- zero
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '1';    -- no detengas la etapa
                stall_to_ma <= '1';    -- no detengas la etapa
                stall_to_wb <= '1';    -- no detengas la etapa
                we_regfl_wb <= '0';    -- Escribe al Register File
                pc_stall_if <= '1';
            when "000110" => -- blez $rs, <offset>
                jmp_type    <= "100";  -- blez
                alu_op_ex   <= "0000"; -- and
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "00";   -- rt
                reg_dest_ex <= "00000";-- zero
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '1';    -- no detengas la etapa
                stall_to_ma <= '1';    -- no detengas la etapa
                stall_to_wb <= '1';    -- no detengas la etapa
                we_regfl_wb <= '0';    -- Escribe al Register File
                pc_stall_if <= '1';
            when "000101" => -- bne $rt, $rs, <offset>
                jmp_type    <= "001";  -- bne
                alu_op_ex   <= "0000"; -- and
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "00";   -- rt
                reg_dest_ex <= "00000";-- zero
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '1';    -- no detengas la etapa
                stall_to_ma <= '1';    -- no detengas la etapa
                stall_to_wb <= '1';    -- no detengas la etapa
                we_regfl_wb <= '0';    -- Escribe al Register File
                pc_stall_if <= '1';
            when "000001" =>
                pc_stall_if <= '1';
                if rt_addr = "00001" then -- bgez $rs, <offset>
                    jmp_type    <= "010";  -- bgez
                    alu_op_ex   <= "0000"; -- and
                    alu_srcA_ex <= "00";   -- rs
                    alu_srcB_ex <= "00";   -- rt
                    reg_dest_ex <= "00000";-- zero
                    opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                    stall_ex    <= '1';    -- no detengas la etapa
                    stall_to_ma <= '1';    -- no detengas la etapa
                    stall_to_wb <= '1';    -- no detengas la etapa
                    we_regfl_wb <= '0';    -- Escribe al Register File
                else                       -- bltz $rs, <offset>
                    jmp_type    <= "101";  -- bltz
                    alu_op_ex   <= "0000"; -- and
                    alu_srcA_ex <= "00";   -- rs
                    alu_srcB_ex <= "00";   -- rt
                    reg_dest_ex <= "00000";-- zero
                    opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                    stall_ex    <= '1';    -- no detengas la etapa
                    stall_to_ma <= '1';    -- no detengas la etapa
                    stall_to_wb <= '1';    -- no detengas la etapa
                    we_regfl_wb <= '0';    -- Escribe al Register File
                end if;
--          when "001000" => -- lb $rt, <offset>($rs)
--
--          when "001000" => -- lbu $rt, <offset>($rs)
--
--          when "001000" => -- lh $rt, <offset>($rs)
--
--          when "001000" => -- lhu $rt, <offset>($rs)
--
--          when "001000" => -- lui $rt, <immed>
--
            when "100011" => -- lw $rt, <offset>($rs)
                alu_op_ex <= "1001";   -- add
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "01";   -- immed
                reg_dest_ex <= "00000";-- rt
                opcode_ma   <= "00";   -- guarda rt en memoria
                stall_ex    <= '0';    -- no detengas la etapa
                stall_to_ma <= '0';    -- no detengas la etapa
                stall_to_wb <= '0';    -- no detengas la etapa
                we_regfl_wb <= '1';    -- Escribe al Register File
            when "001101" => -- ori $rt, $rs, <immed>
                alu_op_ex   <= "0001"; -- or
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "01";   -- immed
                reg_dest_ex <= rt_addr;-- rt
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '0';    -- no detengas la etapa
                stall_to_ma <= '0';    -- no detengas la etapa
                stall_to_wb <= '0';    -- no detengas la etapa
                we_regfl_wb <= '1';    -- Escribe al Register File
--          when "001000" => -- sb $rt, <offset>($rs)
--
            when "001010" => -- slti $rt, $rs, <immed>
                alu_op_ex   <= "0111"; -- sltu
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "01";   -- immed
                reg_dest_ex <= rt_addr;-- rt
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '0';    -- no detengas la etapa
                stall_to_ma <= '0';    -- no detengas la etapa
                stall_to_wb <= '0';    -- no detengas la etapa
                we_regfl_wb <= '1';    -- Escribe al Register File
            when "001011" => -- sltiu $rt, $rs, <immed>
                alu_op_ex   <= "1000"; -- sltu
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "01";   -- immed
                reg_dest_ex <= rt_addr;-- rt
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '0';    -- no detengas la etapa
                stall_to_ma <= '0';    -- no detengas la etapa
                stall_to_wb <= '0';    -- no detengas la etapa
                we_regfl_wb <= '1';    -- Escribe al Register File
--          when "001000" => -- sh $rt, <offset>($rs)
--
            when "101011" => -- sw $rt, <offset>($rs)
                alu_op_ex   <= "1001"; -- add
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "01";   -- immed
                reg_dest_ex <= "00000";-- rt
                opcode_ma   <= "01";   -- guarda rt en memoria
                stall_ex    <= '0';    -- no detengas la etapa
                stall_to_ma <= '0';    -- no detengas la etapa
                stall_to_wb <= '0';    -- no detengas la etapa
                we_regfl_wb <= '0';    -- No escribe al Register File
            when "001110" => -- xori $rt, $rs, <immed>
                alu_op_ex <= "0011";   -- xor
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "01";   -- immed
                reg_dest_ex <= rt_addr;-- rt
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '0';    -- no detengas la etapa
                stall_to_ma <= '0';    -- no detengas la etapa
                stall_to_wb <= '0';    -- no detengas la etapa
                we_regfl_wb <= '1';    -- Escribe al Register File
            when "000010" => -- j <target>
                jmp_type    <= "110";  -- j
                alu_op_ex   <= "0000"; -- and
                alu_srcA_ex <= "00";   -- rs
                alu_srcB_ex <= "00";   -- rt
                reg_dest_ex <= "00000";-- zero
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '1';    -- deten la etapa
                stall_to_ma <= '1';    -- deten la etapa
                stall_to_wb <= '1';    -- deten la etapa
                we_regfl_wb <= '0';    -- Escribe al Register File
                pc_stall_if <= '1';
            when "000011" => -- jal <target>
                jmp_type    <= "110";  -- j
                alu_op_ex   <= "1001"; -- add
                alu_srcA_ex <= "11";   -- 4
                alu_srcB_ex <= "11";   -- pc
                reg_dest_ex <= "11111";-- $31
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '0';    -- no detengas la etapa
                stall_to_ma <= '0';    -- no detengas la etapa
                stall_to_wb <= '0';    -- no detengas la etapa
                we_regfl_wb <= '1';    -- Escribe al Register File
                pc_stall_if <= '1';
            when others =>
                jmp_type    <= "000";  -- j
                alu_op_ex   <= "0000"; -- add
                alu_srcA_ex <= "00";   -- 4
                alu_srcB_ex <= "00";   -- pc
                reg_dest_ex <= "00000";-- $31
                opcode_ma   <= "00";   -- solo pasa resultado de la ALU a WB
                stall_ex    <= '0';    -- no detengas la etapa
                stall_to_ma <= '0';    -- no detengas la etapa
                stall_to_wb <= '0';    -- no detengas la etapa
                we_regfl_wb <= '0';    -- Escribe al Register File
                pc_stall_if <= '0';
        end case;
    end process;

end architecture;
