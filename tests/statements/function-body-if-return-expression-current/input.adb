package body Parent.Child is
  function Pick (value : Integer) return Integer is
  begin
    if Ready then
      return value;
    end if;
    return value;
  end Pick;
end Parent.Child;
