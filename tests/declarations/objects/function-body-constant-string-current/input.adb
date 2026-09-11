package body Parent.Child is
  function Value return Integer is
    expected : constant String := "class";
  begin
    return 1;
  end Value;
end Parent.Child;
