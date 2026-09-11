package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    if Use_Default then
      if Ready then
        raise Program_Error with "default";
      end if;
    else
      declare
        copy : constant Integer := value;
      begin
        if Ready then
          raise Program_Error with "copy";
        end if;
      end;
    end if;
    return value;
  end Wrap;
end Parent.Child;
