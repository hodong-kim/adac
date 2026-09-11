package body Parent.Child is
  procedure Modes
    (Default_Item  : Item;
     Explicit_Item : in Item;
     Updated_Item  : in out Item;
     Output_Item   : out Item)
  is
  begin
    Ada.Text_IO.put_line ("ok");
  end Modes;
end Parent.Child;
