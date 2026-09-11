package body Parent.Child is
  procedure Report is
  begin
    Ada.Text_IO.put_line ("one" & "two");
  end Report;

  procedure Next is
  begin
    null;
  end Next;
end Parent.Child;
