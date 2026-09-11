package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    for item of Items.Values loop
      Validate (item);
    end loop;
    raise Program_Error with "after loop";
    return value;
  end Wrap;
end Parent.Child;
