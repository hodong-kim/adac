package body Parent.Child is
  function Wrap return Integer is
    procedure Helper is
      use type Adac.Source.Position;
      use Adac.Frontend.Tokens;
    begin
      Touch;
    end Helper;
  begin
    return 1;
  end Wrap;
end Parent.Child;
