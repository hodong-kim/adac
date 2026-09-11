package body Parent.Child is
  function Wrap return Boolean is
  begin
    Consume (value => left and right);
    Consume (value => left or right);
    Consume (value => left xor right);
    return True;
  end Wrap;
end Parent.Child;
