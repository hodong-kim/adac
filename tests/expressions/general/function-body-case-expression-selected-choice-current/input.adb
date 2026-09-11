package body Parent.Child is
  function Pick (kind : Kind) return Integer is
  begin
    return (case kind is
      when Adac.AST.Discrete_Range_Loop_Form => 1,
      when others => 0);
  end Pick;
end Parent.Child;
