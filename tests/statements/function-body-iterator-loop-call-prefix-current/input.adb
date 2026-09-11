package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    for item of Items.Values loop
      Validate (item);
      Check (Items.Values);
      null;
    end loop;
    return value;
  end Wrap;
end Parent.Child;
