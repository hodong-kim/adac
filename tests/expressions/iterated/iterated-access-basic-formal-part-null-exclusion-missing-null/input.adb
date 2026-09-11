procedure main is
begin
  return (for Handler : access procedure (Item : not Item_Type)
          of Handlers => Value);
end main;
