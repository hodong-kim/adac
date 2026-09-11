procedure main is
  procedure report_exception
    (prefix : String;
     error  : Ada.Exceptions.Exception_Occurrence)
  is
    name    : constant String := Ada.Exceptions.exception_name (error);
    message : constant String := Ada.Exceptions.exception_message (error);
  begin
    if message'length = 0 then
      Ada.Text_IO.put_line (prefix & name);
    else
      Ada.Text_IO.put_line (prefix & name & ": " & message);
    end if;
  exception
    -- Preserve the primary failure if diagnostic output is unavailable.
    when others =>
      null;
  end report_exception
begin
  null;
end main;
