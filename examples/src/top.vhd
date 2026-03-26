library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library libcore;

entity top is
  port (
    clk : in  std_logic;
    a   : in  unsigned(7 downto 0);
    b   : in  unsigned(7 downto 0);
    y   : out unsigned(7 downto 0)
  );
end entity;

architecture rtl of top is
  component adder is
    generic (W : positive := 8);
    port (
      a : in  unsigned(W-1 downto 0);
      b : in  unsigned(W-1 downto 0);
      y : out unsigned(W-1 downto 0)
    );
  end component;
begin
  u_add : adder
    generic map (W => 8)
    port map (
      a => a,
      b => b,
      y => y
    );
end architecture;

