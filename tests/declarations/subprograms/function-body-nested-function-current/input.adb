package body Parent.Child is
  function Outer return Integer is
    function Inner return Integer is
    begin
      return 1;
    end Inner;
  begin
    return Inner;
  end Outer;
end Parent.Child;
