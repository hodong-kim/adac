package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    if A = B then
      raise Program_Error with "a";
    ElSiF C /= D then
      raise Program_Error with "b";
    elsif E < F then
      raise Program_Error with "c";
    else
      raise Program_Error with "d";
    end if;
    return value;
  end Wrap;
end Parent.Child;
