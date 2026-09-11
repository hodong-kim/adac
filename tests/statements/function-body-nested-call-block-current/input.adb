package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Touch is
    begin
      Helper.Call;
      declare
        local : Integer;
      begin
        local := value;
        if Ready then
          Helper.Call;
        end if;
      end;
    end Touch;
  begin
    return value;
  end Wrap;
end Parent.Child;
