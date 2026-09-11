procedure main is
begin
  return (for Handler : access procedure (Item : in not null Item_Type)
          of Handlers => Value);
end main;
