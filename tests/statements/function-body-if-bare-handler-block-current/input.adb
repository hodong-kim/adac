package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    if Ready then
      begin
        declare
          copy : constant Integer := value;
        begin
          Touch;
        end;
      exception
        when Constraint_Error =>
          Touch;
      end;
    end if;
    return value;
  end Wrap;
end Parent.Child;
