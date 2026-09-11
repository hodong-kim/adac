package body Parent.Child is
  function Make return String_Access is
  begin
    return new String;
  end Make;
end Parent.Child;
