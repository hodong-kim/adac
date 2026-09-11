package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    Items : OS.Argument_List (1 .. 3);
  begin
    return value;
  end Wrap;
end Parent.Child;
