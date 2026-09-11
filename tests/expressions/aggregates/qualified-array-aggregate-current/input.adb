package body Parent.Child is
  function Value return Integer is
    text : constant String := String'(1 => self.lookahead);
  begin
    return 1;
  end Value;
end Parent.Child;
