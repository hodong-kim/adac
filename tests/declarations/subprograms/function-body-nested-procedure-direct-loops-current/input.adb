package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Run is
    begin
      for Index in 1 .. Count loop
        Helper.Call;
      end loop;
      while Ready loop
        Helper.Call;
      end loop;
      loop
        Helper.Call;
      end loop;
    end Run;
  begin
    return value;
  end Wrap;
end Parent.Child;
