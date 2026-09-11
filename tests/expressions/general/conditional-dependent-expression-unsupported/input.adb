package body Parent.Child is
  procedure Run is
    flag : Boolean;
    left : String;
    right : String;
  begin
    if flag then
      Call;
    end if;
    declare
      choice : constant String :=
        (if flag then left and right else "fallback");
    begin
      null;
    end;
  end Run;
end Parent.Child;
