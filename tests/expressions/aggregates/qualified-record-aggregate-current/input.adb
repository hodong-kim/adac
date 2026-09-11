package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    Consume (Pair'(Left => value, Right => value));
    return value;
  end Wrap;
end Parent.Child;
