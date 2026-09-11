package body Parent.Child is
  function Is_Letter (value : Character) return Boolean is
  begin
    return value in 'A' .. 'Z' or else value in 'a' .. 'z';
  end Is_Letter;
end Parent.Child;
