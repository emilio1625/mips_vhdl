library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity alu is
    port (
        sel  : in  std_logic_vector( 3 downto 0);
        op_A : in  std_logic_vector(31 downto 0);
        op_B : in  std_logic_vector(31 downto 0);
        res  : out std_logic_vector(31 downto 0)
    );
end entity;

architecture arch of alu is
begin
    alu : process(sel, op_A, op_B)
    begin
        case sel is
            -- Operaciones Lógicas
            when "0000" => -- and
                res <= op_A and op_B;
            when "0001" => -- or
                res <= op_A or  op_B;
            when "0010" => -- nor
                res <= not (op_A or  op_B);
            when "0011" => -- xor
                res <= op_A xor op_B;
            when "0100" => -- sll
                res <= std_logic_vector(shift_left (unsigned(op_A), to_integer(unsigned(op_B(4 downto 0)))));
            when "0101" => -- srl
                res <= std_logic_vector(shift_right(unsigned(op_A), to_integer(unsigned(op_B(4 downto 0)))));
            when "0110" => -- sra
                res <= std_logic_vector(shift_right(  signed(op_A), to_integer(unsigned(op_B(4 downto 0)))));
            when "0111" => -- slt
                res(31 downto 1) <= (others => '0');
                res(0) <= std_logic_vector(signed(op_A) - signed(op_B))(31);
            when "1000" => -- sltu
                res(31 downto 1) <= (others => '0');
                res(0) <= std_logic_vector(unsigned(op_A) - unsigned(op_B))(31);
            -- Operaciones Aritméticas
            when "1001" => -- add, addu
                res <= std_logic_vector(unsigned(op_A) + unsigned(op_B));
            when "1010" => -- sub, subu
                res <= std_logic_vector(unsigned(op_A) - unsigned(op_B));
            when others =>
                res <= x"00000000";
        end case;
    end process;

end architecture;
