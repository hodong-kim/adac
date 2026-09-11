procedure main is
begin
  return [for Element : Item_Type(Selector)
          in reverse Iterators when Ready => Value];
end main;
