package body Parent.Child is
  function Valid (spelling : String) return Boolean is
  begin
    if spelling'length < 2 or else
       spelling(spelling'first) /= '"' or else
       spelling(spelling'last) /= '"'
    then
      raise Program_Error with "bad";
    end if;
    return True;
  end Valid;
end Parent.Child;
