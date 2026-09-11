package body Parent.Child is
  function Wrap (done : Boolean) return Integer is
  begin
    loop
      declare
        value : Integer := 1;
      begin
        exit when done;
      end;
    end loop;
    return 1;
  end Wrap;
end Parent.Child;
