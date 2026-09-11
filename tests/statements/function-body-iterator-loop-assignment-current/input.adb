package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    for item of Items.Values loop
      Validate (item);
      if Ready then
        raise Program_Error with "bad";
      end if;
      value := item;
      Check (value);
    end loop;
    return value;
  end Wrap;
end Parent.Child;
