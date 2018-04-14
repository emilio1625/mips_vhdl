-- Copyright (c) 2017 Emilio Cabrera <emilio1625@gmail.com>
-- PC Calculation Unit

library ieee;
    use ieee.std_logic_1164.all;
    use ieee.std_logic_unsigned.all;

entity pc_calc is
    port (
        clock: in  std_logic;
        -- Tipo de salto a realizar
        -- +----------------------------+
        -- | opc | instruccion de salto |
        -- |----------------------------+
        -- | 000 | beq $rt, $rs, imm    |
        -- | 001 | bne $rt, $rs, imm    |
        -- | 010 | bgez $rs, imm        |
        -- | 011 | bgtz $rs, imm        |
        -- | 100 | blez $rs, imm        |
        -- | 101 | bltz $rs, imm        |
        -- | 110 | j  target            |
        -- | 111 | jr target            |
        -- +----------------------------+
        opcode : in  std_logic_vector(2 downto 0);
        -- valor del pc actual
        pc_in  : in  std_logic_vector(31 downto 0);
        -- Valor inmediato para saltar (viene de Sign Extend)
        imm    : in  std_logic_vector(31 downto 0);
        -- Valor target para saltar, enviado por la unidad de decodificacion
        target : in  std_logic_vector(25 downto 0);
        -- Valor de $rs para las instrucciones jr jlar
        rs_data: in  std_logic_vector(31 downto 0);
        -- SeÃ±ales de control
        equals : in  boolean; -- '1' si rs == rt
        lesstz : in  boolean; -- '1' si rs < 0
        eq_zero: in  boolean; -- '1' si rs == 0
        -- Salida de carga al pc
        pc_out : out std_logic_vector(31 downto 0)
    );
end entity;

architecture arch of pc_calc is
begin
    pc_calc : process(opcode, equals, lesstz, eq_zero)
    begin
        case opcode is
            when "000" => -- beq $rs, $rt, imm
                if equals  then
                    pc_out <= (pc_in + 4) + (imm(29 downto 0) & "00");
                else
                    pc_out <= pc_in + 4;
                end if;
            when "001" => -- bne $rs, $rt, imm
                if not equals then
                    pc_out <= (pc_in + 4) + (imm(29 downto 0) & "00");
                else
                    pc_out <= pc_in + 4;
                end if;
            when "010" => -- bgtz $rs, imm
                if not lesstz and not eq_zero then
                    pc_out <= (pc_in + 4) + (imm(29 downto 0) & "00");
                else
                    pc_out <= pc_in + 4;
                end if;
            when "011" => -- blez $rs, imm
                if lesstz or eq_zero then
                    pc_out <= (pc_in + 4) + (imm(29 downto 0) & "00");
                else
                    pc_out <= pc_in + 4;
                end if;
            when "100" =>
                if not lesstz then -- bgez $rs, imm
                    pc_out <= (pc_in + 4) + (imm(29 downto 0) & "00");
                else
                    pc_out <= pc_in + 4;
                end if;
            when "101" =>
                if lesstz then -- bltz $rs, imm
                    pc_out <= (pc_in + 4) + (imm(29 downto 0) & "00");
                else
                    pc_out <= pc_in + 4;
                end if;
            when "110" => -- Salto inmmediato
                pc_out <= pc_in(31 downto 28) & target & "00";
            when "111" => -- Salto a un registro
                pc_out <= rs_data;
            when others =>
                pc_out <= pc_in + 4;
        end case;
    end process;

end architecture;
