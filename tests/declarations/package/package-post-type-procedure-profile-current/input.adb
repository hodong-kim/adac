package Parent.Child is
  type Item is private;
  Null_Item : constant Item;
  type Choice is (One, Two, Three);
  type Mode is (Read, Write, Append);
  type Kind is (Primary, Secondary);
  type Form is (Variable_Form, Constant_Form);
  type List is private;
  type Name is private;
  type Literal_List is private;
  procedure Update (self : in out List; node : Item);
end Parent.Child;
