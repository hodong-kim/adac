procedure main is
begin
  return [for Handler : not null access protected procedure
          in reverse Iterators when Ready => Value];
end main;
