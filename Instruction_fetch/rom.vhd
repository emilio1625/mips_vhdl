library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity rom is
port(
    cs       :  in  std_logic;
    addr     :  in  std_logic_vector(31 downto 0);
    data_out :  out std_logic_vector(31 downto 0)
);
end rom;

architecture arch of rom is
    subtype   word          is std_logic_vector(31 downto 0);
    type      memory        is array(0 to 255)  of  word;
    signal    rom           :  memory;
    attribute ram_init_file :  string;
    attribute ram_init_file of rom : signal is "rom.mif";
    signal    data          :  std_logic_vector(31 downto 0);
begin

    rom_p: process(addr) begin
        data <= rom(conv_integer(addr(31 downto 2))); -- Solo direcciones multiplos de 4
    end process rom_p;

    buf_p: process (data, cs) begin
        if cs = '1' then
            data_out <= data;
        else
            data_out <= (others => '0');
        end if;
    end process buf_p;

 end arch;
