package body Parent.Child is
  function Pick (kind : Integer) return Integer is
  begin
    case kind is
      when 1 =>
        return 1;
      when others =>
        return 0;
    end case;
  end Pick;
end Parent.Child;
