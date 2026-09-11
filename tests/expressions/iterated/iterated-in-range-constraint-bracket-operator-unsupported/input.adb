procedure main is
begin
  return [for Cursor : Index_Type range Start .. Limit + 1
          in reverse Iterators when Ready => Value];
end main;
