package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    for Index in Arguments'Range loop
      Helper.Call;
    end loop;
    return value;
  end Wrap;
end Parent.Child;
