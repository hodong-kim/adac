package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    for item of Items.Values loop
      Validate (item);
      if Ready then
        raise Program_Error with "bad";
      end if;
      declare
        copy : constant Types.Span := Source.Value (item).span;
      begin
        Validate (copy);
        if Ready then
          raise Program_Error with "bad block";
        end if;
        copy := Source.Value;
      end;
      null;
    end loop;
    return value;
  end Wrap;
end Parent.Child;
