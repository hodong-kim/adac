package body Parent.Child is
  function Wrap
    (pending : Item; next : Positive; value : Node_ID)
  return Node_ID
  is
  begin
    while next <= list_count (pending) loop
      declare
        current : Node_ID;
      begin
        current := list_element (pending, next);
      end;
      next := next + 1;
    end loop;
    return value;
  end Wrap;
end Parent.Child;
