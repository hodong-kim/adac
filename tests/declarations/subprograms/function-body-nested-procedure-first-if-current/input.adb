package body Parent.Child is
  function Wrap (ready : Boolean) return Integer is
    procedure Check is
    begin
      if ready then
        raise Program_Error with "bad";
      end if;
      raise Program_Error with "bad: " & Target;
    end Check;
  begin
    return 0;
  end Wrap;
end Parent.Child;
