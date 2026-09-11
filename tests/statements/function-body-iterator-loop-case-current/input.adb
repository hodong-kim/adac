package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    for item of Items.Values loop
      case State is
        when Ready | Waiting =>
          Handle (item);
        when others =>
          raise Program_Error with "bad";
      end case;
    end loop;
    return value;
  end Wrap;
end Parent.Child;
