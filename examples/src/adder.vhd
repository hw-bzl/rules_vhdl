library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library libmath;
use libmath.math_pkg.all;

entity adder is
  generic (
    W : positive := 8
  );
  port (
    a : in  unsigned(W-1 downto 0);
    b : in  unsigned(W-1 downto 0);
    y : out unsigned(W-1 downto 0)
  );
end entity;

architecture rtl of adder is
begin
  y <= add_u(a, b);
end architecture;

