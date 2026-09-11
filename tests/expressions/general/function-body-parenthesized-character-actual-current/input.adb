package body Parent.Child is
  function Digit return Integer is
  begin
    return Character'Pos ('0');
  end Digit;
end Parent.Child;
