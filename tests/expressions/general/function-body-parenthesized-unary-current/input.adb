package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    if Ready = (not State.Flags.Empty) then
      raise Program_Error with "bad";
    end if;
    return value;
  end Wrap;
end Parent.Child;
