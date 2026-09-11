procedure main is
begin
  return [for Item : Decimal_Type digits Precision + Offset
          in Iterators => Value];
end main;
