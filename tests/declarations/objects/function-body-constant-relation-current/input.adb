package body Parent.Child is
  function Value return Integer is
    has_items : constant Boolean := Count (Items) /= 0;
  begin
    return 1;
  end Value;
end Parent.Child;
