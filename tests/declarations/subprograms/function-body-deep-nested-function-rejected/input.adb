package body Parent.Child is
  function Outer return Integer is
    function Middle return Integer is
      function Inner return Integer is
      begin
        return 1;
      end Inner;
    begin
      return Inner;
    end Middle;
  begin
    return Middle;
  end Outer;
end Parent.Child;
