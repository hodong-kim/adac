package body Parent.Child is
  function Value return Integer is
  begin
    Helper.Call (First, Left => Third, Second);
    return 1;
  end Value;
end Parent.Child;
