package body Parent.Child is
  function Wrap (self : Context) return Integer is
    has_multiple_choices : Boolean;
  begin
    has_multiple_choices := self.current.kind = Tok_Vertical_Bar;
    return 1;
  end Wrap;
end Parent.Child;
