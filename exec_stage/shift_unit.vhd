library ieee;
    use ieee.std_logic_1164.all;
    use ieee.numeric_std.all;

entity shift_unit is
    port (
        sel  : in  std_logic_vector( 2 downto 0);
        data : in  std_logic_vector(31 downto 0);
        shamt: in  std_logic_vector(31 downto 0);
        res  : out std_logic_vector(31 downto 0)
    );
end entity;

architecture arch of shift_unit is
begin
    shift_sel : process(sel)
    begin
        case sel is
            when "00" =>
                res <= to_unsigned(data) sll to_integer(shamt);
            when "01" =>
                res <= to_unsigned(data) srl to_integer(shamt);
            when "10" =>
                res <= to_unsigned(data) sla to_integer(shamt);
            when others =>
                res <= to_unsigned(data) sra to_integer(shamt);
        end case;
    end process;

end architecture;
