procedure main is
begin
  return [for Handler : not null access protected function
          return not null access constant Result_Type
          in reverse Handlers when Ready => Value];
end main;
