package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    if Empty then
      raise Program_Error with "empty";
    end if;
    return value;
  end Wrap;
end Parent.Child;
