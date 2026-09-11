package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Touch is
      local : Integer;
    begin
      Helper.Call;
      declare
        inner : Integer;
      begin
        for item of Items.Values loop
          inner := value;
        end loop;
      end;
    end Touch;
  begin
    return value;
  end Wrap;
end Parent.Child;
