library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package math_pkg is
  function add_u(a : unsigned; b : unsigned) return unsigned;
end package;

package body math_pkg is
  function add_u(a : unsigned; b : unsigned) return unsigned is
    variable r : unsigned(a'range);
  begin
    r := a + b;
    return r;
  end function;
end package body;

