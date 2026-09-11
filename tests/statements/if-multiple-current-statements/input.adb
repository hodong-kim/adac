package body Parent.Child is
  procedure Run is
    flag : Boolean;
  begin
    if flag then
      First;
      Second;
      return;
    end if;
  end Run;
end Parent.Child;
