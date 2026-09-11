package body Parent.Child is
  function Sequence (stack_size : Natural) return String is
  begin
    return
      (if stack_size = 0
       then Return_Sequence
       else Framed_Return_Sequence);
  end Sequence;
end Parent.Child;
