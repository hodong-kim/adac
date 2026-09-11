package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Forward (item : Integer);
    procedure Outer is
      procedure Inner (item : Integer);
    begin
      Helper.Call;
    end Outer;
  begin
    return value;
  end Wrap;
end Parent.Child;
