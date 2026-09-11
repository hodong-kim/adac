procedure main is
begin
  if Ready then
    Ada.Text_IO.put_line (Value);
  else
    Ada.Text_IO.put_line (Other);
  end;
end main;
