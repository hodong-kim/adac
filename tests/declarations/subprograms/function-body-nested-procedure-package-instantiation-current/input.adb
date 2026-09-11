package body Parent.Child is
  function Wrap return Integer is
    procedure Helper is
      package Frames is new Ada.Containers.Vectors
        (Index_Type => Positive, Element_Type => Frame);
    begin
      Touch;
    end Helper;
  begin
    return 1;
  end Wrap;
end Parent.Child;
