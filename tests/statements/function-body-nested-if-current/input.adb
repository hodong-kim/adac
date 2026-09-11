package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    if Outer then
      if Middle then
        if Inner then
          raise Program_Error with "bad";
        else
          Check (value);
        end if;
      end if;
    end if;
    return value;
  end Wrap;
end Parent.Child;
