package body Parent.Child is
  function Wrap (value : Integer) return Integer is
    result : Integer := value;
  begin
    if Ready then
      result := value;
    elsif Other then
      result := value;
    else
      result := value;
    end if;
    return result;
  end Wrap;
end Parent.Child;
