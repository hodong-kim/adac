package body Parent.Child is
  function Value return Integer is
  begin
    Helper.Call (First, Second, Left => Third, Right => Fourth);
    return 1;
  end Value;
end Parent.Child;
