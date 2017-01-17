-- Copyright (c) 2017 Emilio Cabrera <emilio1625@gmail.com>
-- Instruction Fetch Subsystem (IF)

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity instruction_fetch is
    port (
        clock      : in  std_logic;
        -- Indican si debemos brincar (1), o calcular de forma normal el valor de PC (0)
        branch, jmp: in  std_logic := '0';
        -- Direccion a donde saltar
        branch_addr: in  std_logic_vector(31 downto 0);
        jmp_addr   : in  std_logic_vector(31 downto 0);
        -- Instruccion que sera enviada a Instruction Decode
        instruction: out std_logic_vector(31 downto 0);
        -- salida del PC
        pc_out     : out std_logic_vector(31 downto 0);
        -- Indica si debemos detener el fetch (1) por una instruccion en el pipeline
        stall      : in std_logic := '0'
    );
end entity;

architecture arch of instruction_fetch is
    -- Program Counter Register
    signal pc         : std_logic_vector(29 downto 0) := (others => '0');
begin
    code_rom: entity work.rom port map(
        cs       => '1',
        addr     => pc & "00", -- Solo direcciones multiplos de 4
        data_out => instruction
    );

    pc_update: process(clock) begin
        if rising_edge(clock) then
            if stall = '1' then
                pc <= pc; -- no modifiques el contenido del PC
            elsif branch = '1' then -- realiza un salto
                pc <= branch_addr(31 downto 2);
            elsif jmp = '1' then -- realiza un salto
                pc <= jmp_addr(31 downto 2);
            else
                pc <= pc + 1;
            end if;
        end if;
    end process;

    pc_out <= pc & "00"; -- enviamos el valor del pc a la siguiente etapa

end architecture;
