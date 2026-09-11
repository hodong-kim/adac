package body Parent.Child is
  function Wrap (value : Integer) return Integer is
  begin
    if value /= Other or else
       (Previous /= First and then not Ready)
    then
      Touch;
    end if;
    return value;
  end Wrap;
end Parent.Child;
