package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    for item of Items.Values loop
      null;
    end loop;
    return value;
  end Wrap;
end Parent.Child;
