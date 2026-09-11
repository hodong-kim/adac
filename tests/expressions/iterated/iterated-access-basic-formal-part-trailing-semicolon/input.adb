procedure main is
begin
  return (for Handler : access procedure (Item : Item_Type;)
          of Handlers => Value);
end main;
