entity mixed is
end entity;

architecture rtl of mixed is
    component vlog_dep
    end component;
begin
    vlog_dep_inst : vlog_dep;
end architecture;
