procedure main is
begin
  return [for Item : not null access Ref_Type
          in reverse Iterators when Ready => Value];
end main;
