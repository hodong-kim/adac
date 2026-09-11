package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Touch is
    begin
      Helper.Call;
      case State is
        when Ready =>
          Helper.Call;
        when others =>
          null;
      end case;
    end Touch;
  begin
    return value;
  end Wrap;
end Parent.Child;
