package body Parent.Child is
  function Value return Integer is
  begin
    declare
      result : Integer := 1;
    begin
      return result;
    end;
  end Value;
end Parent.Child;
