package body Parent.Child is
  function Wrap return Integer is
    procedure Helper
      (mode : Integer := Default_Mode;
       enabled : Boolean := False;
       text : String := "")
    is
    begin
      Touch;
    end Helper;
  begin
    return 1;
  end Wrap;
end Parent.Child;
