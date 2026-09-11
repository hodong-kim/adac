package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    local : Integer;
  begin
    return Helper.Call (local, value);
  end Wrap;
end Parent.Child;
