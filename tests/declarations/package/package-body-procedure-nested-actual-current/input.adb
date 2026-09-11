package body Adac.Driver is
  procedure p (context : Adac.Compilation.Context) is
  begin
    Ada.Text_IO.put_line
      ("x" & Adac.Support.image
         (Adac.Compilation.Diagnostics.error_count (context)));
  end p;
end Adac.Driver;
