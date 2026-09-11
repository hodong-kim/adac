package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    result : Integer;
  begin
    Validate (value);
    result := Convert (value);
    null;
    return result;
  end Wrap;
end Parent.Child;
