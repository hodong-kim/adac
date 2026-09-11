package body Parent.Child is
  function Pick (value : Integer) return Integer is
  begin
    case Outer is
      when Ready =>
        case Inner is
          when Ready =>
            Helper.Call;
          when others =>
            null;
        end case;
      when others =>
        null;
    end case;
    return value;
  end Pick;
end Parent.Child;
