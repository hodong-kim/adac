package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Reset is
    begin
      File := OS.Invalid_FD;
      Path := Unbounded.Null_Unbounded_String;
      Helper.Call;
    end Reset;
  begin
    return value;
  end Wrap;
end Parent.Child;
