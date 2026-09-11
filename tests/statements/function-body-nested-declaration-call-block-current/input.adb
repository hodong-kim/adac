package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Touch is
      local : Integer;
    begin
      Helper.Call;
      declare
        inner : Integer;
      begin
        inner := value;
      end;
    end Touch;
  begin
    return value;
  end Wrap;
end Parent.Child;
