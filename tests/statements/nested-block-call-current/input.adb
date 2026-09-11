package body Parent.Child is
  procedure Run is
    flag : Boolean;
  begin
    if flag then
      First;
    end if;
    declare
    begin
      Next;
    end;
  end Run;
end Parent.Child;
