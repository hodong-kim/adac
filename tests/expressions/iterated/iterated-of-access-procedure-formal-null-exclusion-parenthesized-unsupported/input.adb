procedure main is
begin
  return (for Handler : access procedure (Item : not null Item_Type)
          of Handlers => Value);
end main;
