procedure main is
begin
  return (for Element : access Item_Ref range 1 .. 10 of Items => Value);
end main;
