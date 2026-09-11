procedure main is
begin
  return (for Handler : access function return access procedure
          (Item : Item_Type) of Handlers => Value);
end main;
