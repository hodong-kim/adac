package body Parent.Child is
  function Trim (raw : String) return String is
  begin
    return raw(raw'first + 1 .. raw'last);
  end Trim;
end Parent.Child;
