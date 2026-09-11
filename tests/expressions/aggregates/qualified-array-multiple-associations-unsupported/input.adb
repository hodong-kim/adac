package body Parent.Child is
  function Value return Integer is
    text : constant String :=
      String'(1 => self.first, 2 => self.second);
  begin
    return 1;
  end Value;
end Parent.Child;
