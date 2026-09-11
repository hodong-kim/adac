package body Parent.Child is
  function Wrap return Item is
  begin
    return Build (first => value, trailing);
  end Wrap;
end Parent.Child;
