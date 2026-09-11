package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    procedure Touch is
      local : Integer;
    begin
      Helper.Call;
    exception
      when Constraint_Error =>
        local := value;
        Helper.Call;
    end Touch;
  begin
    return value;
  end Wrap;
end Parent.Child;
