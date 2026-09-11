procedure main is
begin
  return [for Element : Item_Type(First, Disc | Other => Choice)
          in reverse Items when Ready => Value];
end main;
