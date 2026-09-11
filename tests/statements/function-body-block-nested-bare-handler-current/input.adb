package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    declare
      result : Integer := value;
    begin
      Touch;
      begin
        result := value;
      exception
        when Constraint_Error =>
          result := value;
          Touch;
      end;
      Touch;
    end;
    return value;
  end Wrap;
end Parent.Child;
