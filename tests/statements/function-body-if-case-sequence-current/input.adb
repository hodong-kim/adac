package body Parent.Child is
  function Value (ready : Boolean) return Integer is
  begin
    if ready then
      return 1;
    else
      if Guard then
        Touch;
      end if;
      case State is
        when One =>
          Touch;
        when others =>
          Touch;
      end case;
    end if;
    return 0;
  end Value;
end Parent.Child;
