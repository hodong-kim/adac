package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    case State is
      when Ready | Waiting =>
        Handle (value);
        declare
          local : Integer;
        begin
          local := value;
        end;
      when others =>
        raise Program_Error with "bad";
    end case;
    return value;
  end Wrap;
end Parent.Child;
