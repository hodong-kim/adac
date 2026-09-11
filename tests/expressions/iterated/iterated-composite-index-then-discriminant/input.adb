procedure main is
begin
  return (for Element : Item_Type(1 .. Limit, Disc => Choice)
          of Items => Value);
end main;
