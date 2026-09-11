package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Run is
      Local : Integer;
    begin
      while Ready loop
        Helper.Call;
      end loop;
      Helper.Call;
    end Run;
  begin
    return value;
  end Wrap;
end Parent.Child;
