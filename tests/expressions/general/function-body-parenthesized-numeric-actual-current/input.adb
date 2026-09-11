package body Parent.Child is
  function Apostrophe return Character is
  begin
    return Character'Val (16#27#);
  end Apostrophe;
end Parent.Child;
