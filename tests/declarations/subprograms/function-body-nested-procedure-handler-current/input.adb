package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Touch is
      local : Integer;
    begin
      Helper.Call;
      local := value;
    exception
      when others =>
        null;
    end Touch;
  begin
    return value;
  end Wrap;
end Parent.Child;
