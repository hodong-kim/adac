package body Parent.Child is
  function Classify (kind : Token_Kind) return Integer is
  begin
    return
      (case kind is
         when Alpha | Beta => 1,
         when others => raise Parse_Error with "bad kind");
  end Classify;
end Parent.Child;
