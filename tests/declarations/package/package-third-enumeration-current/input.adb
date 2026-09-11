package Parent.Child is
  type Item is private;
  Null_Item : constant Item;
  type Choice is (One, Two, Three);
  type Mode is (Read, Write, Append);
  type Form is (Variable, Fixed);
  procedure Next;
end Parent.Child;
