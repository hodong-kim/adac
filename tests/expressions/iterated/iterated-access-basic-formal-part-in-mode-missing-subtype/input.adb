procedure main is
begin
  return (for Handler : access procedure (Item : in)
          of Handlers => Value);
end main;
