package body Parent.Child is
  function Wrap (self : Context) return Integer is
    allow_in_filter : Boolean;
  begin
    allow_in_filter := not self.failed;
    return 1;
  end Wrap;
end Parent.Child;
