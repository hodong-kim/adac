package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    declare
      result : Integer := value;
    begin
      Touch;
      result := value;
    end;
    return value;
  end Wrap;
end Parent.Child;
