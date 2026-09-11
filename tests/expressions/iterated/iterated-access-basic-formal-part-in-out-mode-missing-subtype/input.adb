procedure main is
begin
  return (for Handler : access procedure (Item : in out)
          of Handlers => Value);
end main;
