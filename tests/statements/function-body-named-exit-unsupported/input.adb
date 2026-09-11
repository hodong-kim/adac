package body Parent.Child is
  function Run (terminated : Boolean) return Boolean is
  begin
    loop
      exit Outer when terminated;
      Helper.Call;
    end loop;
    return terminated;
  end Run;
end Parent.Child;
