package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    if A = B then
      raise Program_Error with "eq";
    end if;
    if C /= D then
      raise Program_Error with "ne";
    end if;
    if E < F then
      raise Program_Error with "lt";
    end if;
    if G <= H then
      raise Program_Error with "le";
    end if;
    if I > J then
      raise Program_Error with "gt";
    end if;
    if K >= L then
      raise Program_Error with "ge";
    end if;
    return value;
  end Wrap;
end Parent.Child;
