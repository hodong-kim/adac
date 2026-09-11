procedure main is
begin
  return (for Element : Item_Type(First + Offset, 1 .. Limit)
          of Items => Value);
end main;
