package body Parent.Child is
  function Value (ready : Boolean) return Integer is
  begin
    loop
      if ready then
        return 1;
      end if;
    end loop;
  end Value;
end Parent.Child;
