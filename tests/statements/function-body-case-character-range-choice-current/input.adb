package body Parent.Child is
  function Pick (kind : Character) return Integer is
  begin
    case kind is
      when '0' .. '9' =>
        return 1;
      when others =>
        return 0;
    end case;
  end Pick;
end Parent.Child;
