procedure main is
begin
  return [for Index in 1 .. Limit use Key + Offset => Value];
end main;
