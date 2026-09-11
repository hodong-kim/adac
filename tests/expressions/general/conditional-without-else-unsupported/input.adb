package body Parent.Child is
  procedure Run is
    flag : Boolean;
  begin
    if flag then
      Call;
    end if;
    declare
      choice : constant String :=
        (if flag then "a");
    begin
      null;
    end;
  end Run;
end Parent.Child;
