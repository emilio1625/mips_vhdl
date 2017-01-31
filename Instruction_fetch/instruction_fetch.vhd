-- Copyright (c) 2017 Emilio Cabrera <emilio1625@gmail.com>
-- Instruction Fetch Subsystem (IF)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity instruction_fetch is
    port (
        clock      : in  std_logic;
        -- Indican si debemos brincar (1), o calcular de forma normal el valor de PC (0)
        jmp        : in  std_logic := '0';
        -- Direccion a donde saltar
        jmp_addr   : in  std_logic_vector(31 downto 0);
        -- Instruccion que sera enviada a Instruction Decode
        instruction: out std_logic_vector(31 downto 0);
        -- Salida del PC, este valor es la instruccion siguiente a ejecutar
        pc_out     : out std_logic_vector(31 downto 0);
        -- Indica si debemos detener el fetch (1) por una instruccion en el pipeline
        stall      : in std_logic := '0'
    );
end entity;

architecture arch of instruction_fetch is
    -- Program Counter Register, siempre almacena la instruccion siguiente a ejecutar
    signal pc_next    : std_logic_vector(29 downto 0) := (others => '0');
    signal pc_current : std_logic_vector(29 downto 0) := (others => '0');
    signal instr_reg  : std_logic_vector(31 downto 0) := (others => '0');
begin
    code_rom: entity work.rom port map(
        cs       => '1',
        addr     => pc_current & "00", -- Solo direcciones multiplos de 4
        data_out => instr_reg
    );

    pc_update: process(clock) begin
        if rising_edge(clock) then
            if stall = '1' then
                pc_next <= pc_current; -- no modifiques el contenido del PC
            elsif jmp = '1' then -- realiza un salto
                pc_next <= jmp_addr(31 downto 2);
            else
                pc_next <= pc_current + 1;
            end if;
        end if;
        instruction <= instr_reg;
        pc_current <= pc_next;
    end process;

    pc_out <= pc_current & "00"; -- enviamos el valor del pc a la siguiente etapa

end architecture;
