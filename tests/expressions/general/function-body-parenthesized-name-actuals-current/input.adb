package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    return OS.Write
      (File,
       Content(Content'First + Offset)'Address,
       Content'Length - Offset);
  end Wrap;
end Parent.Child;
