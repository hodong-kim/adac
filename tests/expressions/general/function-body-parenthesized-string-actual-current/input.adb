package body Parent.Child is
  function Pick (value : Integer) return Integer is
  begin
    if Ada.Environment_Variables.Exists ("ADAC_CC") then
      return value;
    end if;
    return value;
  end Pick;
end Parent.Child;
