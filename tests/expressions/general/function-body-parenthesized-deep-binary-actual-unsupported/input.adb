package body Parent.Child is
  function Next (value : Integer) return Integer is
  begin
    return Outer (Middle (Inner (value) + 1) + 1);
  end Next;
end Parent.Child;
