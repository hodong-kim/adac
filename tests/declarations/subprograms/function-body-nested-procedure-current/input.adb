package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Touch is
      procedure Check (current : Integer);
      procedure Check (current : Integer) is
      begin
        null;
      end Check;
      local : Integer;
    begin
      Helper.Call;
      case local is
        when Ready =>
          Helper.Call;
        when others =>
          null;
      end case;
      local := value;
      if local = value then
        Helper.Call;
      end if;
      local := value;
    end Touch;
  begin
    return value;
  end Wrap;
end Parent.Child;
