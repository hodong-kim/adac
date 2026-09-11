package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    current : Integer := value;
  begin
    loop
      current := value;
      declare
        inner : Integer;
      begin
        inner := current;
      end;
    end loop;
    return current;
  end Wrap;
end Parent.Child;
