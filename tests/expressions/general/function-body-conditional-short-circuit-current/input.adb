package body Parent.Child is
  function Sequence
    (ready : Boolean; left : Boolean; right : Boolean)
  return String is
  begin
    return
      (if not ready and then (left or else right)
       then Return_Sequence
       else Framed_Return_Sequence);
  end Sequence;
end Parent.Child;
