package body Parent.Child is
  procedure Run is
    flag : Boolean;
    other : Boolean;
  begin
    if flag then
      Call;
    end if;
    declare
      choice : constant String :=
        (if flag then "a" elsif other then "b" else "c");
    begin
      null;
    end;
  end Run;
end Parent.Child;
