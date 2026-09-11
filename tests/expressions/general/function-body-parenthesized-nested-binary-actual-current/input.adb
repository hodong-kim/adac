package body Parent.Child is
  function Next (value : Integer) return Integer is
  begin
    return Positive (Natural (value) + 1);
  end Next;
end Parent.Child;
