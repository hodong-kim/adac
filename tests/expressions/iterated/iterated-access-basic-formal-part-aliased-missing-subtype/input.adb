procedure main is
begin
  return (for Handler : access procedure (Item : aliased)
          of Handlers => Value);
end main;
