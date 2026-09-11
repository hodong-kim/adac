package body Parent.Child is
  procedure Run is
    flag : Boolean;
  begin
    if flag then
      First;
    end if;
    if not flag then
      Second;
      return;
    end if;
    declare
      choice : constant String :=
        (if flag then First_Value else "fallback");
    begin
      null;
    end;
  end Run;
end Parent.Child;
