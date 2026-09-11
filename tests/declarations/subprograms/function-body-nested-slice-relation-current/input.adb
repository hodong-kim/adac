package body Parent.Child is
  function Is_Operator_Symbol (text : String) return Boolean is
  begin
    return operator_kind (text(text'First + 1 .. text'Last - 1)) /=
      Tok_Unknown;
  end Is_Operator_Symbol;
end Parent.Child;
