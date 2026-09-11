package body Parent.Child is
  function Value return Integer is
    procedure Touch is
      Local : constant Integer := 1;
    begin
      Helper.Call;
      begin
        Helper.Call;
      exception
        when others =>
          raise;
      end;
    end Touch;
  begin
    return 1;
  end Value;
end Parent.Child;
