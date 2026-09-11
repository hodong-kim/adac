procedure main is
begin
  return [for Handler : not null access protected function
          return not null Result_Type
          in reverse Iterators when Ready => Value];
end main;
