procedure main is
begin
  return [for Handler : access procedure (Item : in access Item_Type)
          in Handlers => Value];
end main;
