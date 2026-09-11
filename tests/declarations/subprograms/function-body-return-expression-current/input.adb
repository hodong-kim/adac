package body Parent.Child is
  function Wrap
    (value : Integer;
     fallback : Integer := Default_Value)
    return Integer is
  begin
    return Helper.Call (value, fallback);
  end Wrap;
end Parent.Child;
