package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    declare
      result : Integer := value;
    begin
      Touch;
      result := value;
    exception
      when others =>
        Touch;
        raise;
    end;
    return value;
  end Wrap;
end Parent.Child;
