package body Parent.Child is
  procedure First is
  begin
    Ada.Text_IO.put_line ("one");
  end First;

  procedure Second is
  begin
    Ada.Text_IO.put_line ("two");
  end Second;
end Parent.Child;
