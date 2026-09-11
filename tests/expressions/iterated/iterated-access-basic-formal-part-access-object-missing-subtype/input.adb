procedure main is
begin
  return [for Handler : access procedure (Item : access constant)
          in Handlers => Value];
end main;
