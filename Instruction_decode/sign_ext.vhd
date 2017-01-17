-- Copyright (c) 2017 Emilio Cabrera <emilio1625@gmail.com>
-- 16 to 32 bit Sign Extend Unit

library ieee;
use ieee.std_logic_1164.all;

entity sign_ext is
  port (
    data_in:  in  std_logic_vector(15 downto 0);
    data_out: out std_logic_vector(31 downto 0);
  );
end entity;

architecture arch of sign_ext is
begin
    data_out <= x"0000" & data_in when data_in(15) = '0' else -- si no tiene signo
                x"FFFF" & data_in; -- si tiene signo conservalo
end architecture;
