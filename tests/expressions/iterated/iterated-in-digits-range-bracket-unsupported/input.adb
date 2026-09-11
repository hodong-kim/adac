procedure main is
begin
  return [for Item : Decimal_Type digits Precision
          range Low .. High
          in reverse Iterators when Ready => Value];
end main;
