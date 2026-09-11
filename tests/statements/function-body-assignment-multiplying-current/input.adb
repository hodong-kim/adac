package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    result : Integer := value;
  begin
    result := value * 2 / 1;
    return result;
  end Wrap;
end Parent.Child;
